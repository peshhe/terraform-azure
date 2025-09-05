# Get info for the core infra Resource Group
data "azurerm_resource_group" "rg_core_infra" {
  name = "rg-sandbox-assignment-core-infra"
}

# Get info for the core infra Virtual Network
data "azurerm_virtual_network" "vnet_core_infra" {
  name                = "vnet-assignment"
  resource_group_name = data.azurerm_resource_group.rg_core_infra.name
}

# Create subnet for the bastion
resource "azurerm_subnet" "subnet_bastion" {
  name                 = "sn-${var.common_name}"
  resource_group_name  = data.azurerm_resource_group.rg_core_infra.name
  virtual_network_name = data.azurerm_virtual_network.vnet_core_infra.name
  address_prefixes     = ["10.20.4.0/24"]
}

# Create a NSG for the bastion and allow inbound SSH from my personal IP only
resource "azurerm_network_security_group" "nsg_bastion" {
  name                = "nsg-vm-nic-${var.common_name}"
  location            = data.azurerm_resource_group.rg_core_infra.location
  resource_group_name = data.azurerm_resource_group.rg_core_infra.name
  tags                = local.common_tags

  security_rule {
    name                       = "Allow-SSH-Inbound-${var.common_name}"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ip_address # restricted to a single IP for security
    destination_address_prefix = "*"
  }
}

# Create public IP to access the Bastion VM
resource "azurerm_public_ip" "terraform_public_ip_bastion" {
  name                = "public-ip-vm-${var.common_name}"
  location            = data.azurerm_resource_group.rg_core_infra.location
  resource_group_name = data.azurerm_resource_group.rg_core_infra.name
  allocation_method   = "Static"
  tags                = local.common_tags
}

# Create a Network Interface Card, required for the Virtual Machine
resource "azurerm_network_interface" "nic_bastion" {
  name                = "nic-vm-${var.common_name}"
  location            = data.azurerm_resource_group.rg_core_infra.location
  resource_group_name = data.azurerm_resource_group.rg_core_infra.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "ip-conf-nic-${var.common_name}-vm"
    subnet_id                     = azurerm_subnet.subnet_bastion.id
    public_ip_address_id          = azurerm_public_ip.terraform_public_ip_bastion.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the NIC to the NSG
resource "azurerm_network_interface_security_group_association" "tf-link-nic-nsg" {
  network_interface_id      = azurerm_network_interface.nic_bastion.id
  network_security_group_id = azurerm_network_security_group.nsg_bastion.id
}

# Create the actual Bastion Virtual Machine
resource "azurerm_virtual_machine" "main_bastion" {
  name                  = "vm-${var.common_name}"
  location              = data.azurerm_resource_group.rg_core_infra.location
  resource_group_name   = data.azurerm_resource_group.rg_core_infra.name
  network_interface_ids = [azurerm_network_interface.nic_bastion.id]
  vm_size               = "Standard_B1s" # 1 vcpus, 1 GB RAM
  tags                  = local.common_tags

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "vm-${var.common_name}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.common_name}-vm"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}
