# Get information for the core infra Resource Group
data "azurerm_resource_group" "rg_core_infra" {
  name = "rg-sandbox-${var.common_name}-core-infra"
}

# Get information for the core infra Virtual Network
data "azurerm_virtual_network" "vnet_core_infra" {
  name                = "vnet-${var.common_name}"
  resource_group_name = data.azurerm_resource_group.rg_core_infra.name
}

# Get information for the core infra Subnet for the specific environment
data "azurerm_subnet" "subnet_core_infra" {
  name                 = "sn-${var.common_name}-${var.environment}"
  virtual_network_name = data.azurerm_virtual_network.vnet_core_infra.name
  resource_group_name  = data.azurerm_resource_group.rg_core_infra.name
}

# Get information for the core infra Subnet for the Cosmos DB
data "azurerm_subnet" "subnet_cosmos_db" {
  name                 = "sn-${var.common_name}-cosmosdb"
  virtual_network_name = data.azurerm_virtual_network.vnet_core_infra.name
  resource_group_name  = data.azurerm_resource_group.rg_core_infra.name
}

# Create a Resource Group for the specific environment
resource "azurerm_resource_group" "rg_main" {
  location = var.location
  name     = "rg-sandbox-${var.common_name}-${var.environment}"
  tags     = local.common_tags
}

# Create a Cosmos DB account
resource "azurerm_cosmosdb_account" "cosmosdb_account_main" {
  name                = "azure-cosmos-db-${var.common_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg_main.name
  location            = azurerm_resource_group.rg_main.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  free_tier_enabled   = true
  tags                = local.common_tags

  # Allow access to the DB from specific IP(s) - in my case this is range of IPs:
  # LB's IP - to allow access from VMs; my own IP for management/demo
  ip_range_filter = [azurerm_public_ip.terraform_public_ip_lb.ip_address, var.allowed_ip_address]

  is_virtual_network_filter_enabled = true
  # Allow access only from specific subnets
  virtual_network_rule {
    id = data.azurerm_subnet.subnet_cosmos_db.id
  }

  consistency_policy {
    consistency_level = "Session"
  }
  geo_location {
    location          = azurerm_resource_group.rg_main.location
    failover_priority = 0
    zone_redundant    = false
  }
}

# Create a database within the Cosmos DB Account
resource "azurerm_cosmosdb_sql_database" "database_main" {
  name                = "loadbalancer_demo_db_${var.environment}"
  resource_group_name = azurerm_resource_group.rg_main.name
  account_name        = azurerm_cosmosdb_account.cosmosdb_account_main.name
}

# Create a container within the database
resource "azurerm_cosmosdb_sql_container" "container_main" {
  name                = "vm_records"
  resource_group_name = azurerm_resource_group.rg_main.name
  account_name        = azurerm_cosmosdb_account.cosmosdb_account_main.name
  database_name       = azurerm_cosmosdb_sql_database.database_main.name
  partition_key_paths = ["/id"]
}

# Create NSG for VMs and allow Inbound HTTP access
resource "azurerm_network_security_group" "nsg_main" {
  name                = "nsg-vm-nic-${var.common_name}-${var.environment}"
  location            = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name
  tags                = local.common_tags

  security_rule {
    name                       = "Allow-HTTP-Inbound-${var.environment}"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create (multiple) Network Interface Card(s) (NICs) for the VMs
resource "azurerm_network_interface" "nic_main" {
  count               = var.number_of_instances
  name                = "nic-vm-${count.index + 1}-${var.common_name}-${var.environment}"
  location            = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "ip-conf-nic-vm"
    subnet_id                     = data.azurerm_subnet.subnet_core_infra.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the (multiple) NIC(s) to the NSG
resource "azurerm_network_interface_security_group_association" "tf-link-nic-nsg" {
  count                     = var.number_of_instances
  network_interface_id      = azurerm_network_interface.nic_main[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg_main.id
}

# Create (multiple) VM(s)
resource "azurerm_virtual_machine" "main" {
  count                 = var.number_of_instances
  name                  = "vm-${count.index + 1}-${var.common_name}-${var.environment}"
  location              = azurerm_resource_group.rg_main.location
  resource_group_name   = azurerm_resource_group.rg_main.name
  network_interface_ids = [azurerm_network_interface.nic_main[count.index].id]
  vm_size               = "Standard_B1s" # 1 vcpus, 1 GB RAM
  # vm_size               = "Standard_B2ls_v2" # 2 vcpus, 4 GB RAM
  # vm_size               = "Standard_D2s_v3" # 2 vcpus, 8 GB RAM

  tags                             = local.common_tags
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "vm-${count.index + 1}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.common_name}-${var.environment}-vm-${count.index + 1}"
    admin_username = var.admin_username
    admin_password = var.admin_password

    custom_data = base64encode(templatefile("${path.module}/vm-init.sh", {
      environment          = var.environment
      index                = "${count.index + 1}"
      location             = var.location
      slack_url            = var.slack_url
      cosmosdb_endpoint    = azurerm_cosmosdb_account.cosmosdb_account_main.endpoint
      cosmosdb_primary_key = azurerm_cosmosdb_account.cosmosdb_account_main.primary_key
      database_name        = azurerm_cosmosdb_sql_database.database_main.name
      container_name       = azurerm_cosmosdb_sql_container.container_main.name
    }))
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Create public IP for the LB - which the webapps can be accessed on
resource "azurerm_public_ip" "terraform_public_ip_lb" {
  name                = "public-ip-lb-${var.common_name}-${var.environment}"
  location            = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name
  allocation_method   = "Static"
  tags                = local.common_tags
}

# Create a Load Balancer
resource "azurerm_lb" "lb_main" {
  name                = "lb-${var.common_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg_main.name
  location            = azurerm_resource_group.rg_main.location
  tags                = local.common_tags

  frontend_ip_configuration {
    name                 = "frontend-public-ip-address"
    public_ip_address_id = azurerm_public_ip.terraform_public_ip_lb.id
  }
}

# Backend Address Pool for the LB
resource "azurerm_lb_backend_address_pool" "web_servers" {
  loadbalancer_id = azurerm_lb.lb_main.id
  name            = "webapp-servers-pool-${var.environment}"
}

# Connect the backend pool of the LB to the NIC(s) - basically connect the VM(s) to the LB
resource "azurerm_network_interface_backend_address_pool_association" "web_vm_lb_association" {
  count                   = var.number_of_instances
  network_interface_id    = azurerm_network_interface.nic_main[count.index].id
  ip_configuration_name   = azurerm_network_interface.nic_main[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_servers.id
}

# Health Probe for HTTP
resource "azurerm_lb_probe" "web_health_probe" {
  loadbalancer_id     = azurerm_lb.lb_main.id
  name                = "web-health-probe-http-${var.environment}"
  protocol            = "Http"
  port                = 80
  request_path        = "/" # Should be adjusted to the proper health check endpoint
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Load Balancing Rule for HTTP
resource "azurerm_lb_rule" "web_lb_rule" {
  loadbalancer_id                = azurerm_lb.lb_main.id
  name                           = "web-lb-rule-${var.environment}"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.lb_main.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_servers.id]
  probe_id                       = azurerm_lb_probe.web_health_probe.id
  disable_outbound_snat          = true
}

# Outbound Rule for SNAT (Source Network Address Translation) - this is recommended for the Standard LB
resource "azurerm_lb_outbound_rule" "web_outbound_rule" {
  name                    = "web-outbound-rule-${var.environment}"
  loadbalancer_id         = azurerm_lb.lb_main.id
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_servers.id

  frontend_ip_configuration {
    name = azurerm_lb.lb_main.frontend_ip_configuration[0].name
  }
}
