# Create a Resource Group to hold all the core infra Resources within
resource "azurerm_resource_group" "rg_core_infra_tfstate" {
  location = var.location
  name     = "rg-sandbox-${var.common_name}-core-infra"
  tags     = local.common_tags
}

# Create a Storaga Account that would hold the Terraform State file
resource "azurerm_storage_account" "storage_account_core_infra_tfstate" {
  name                     = var.storage_account_name # only lowercase letters and numbers (3-24); no dashes, special characters etc.; globally unique;
  resource_group_name      = azurerm_resource_group.rg_core_infra_tfstate.name
  location                 = azurerm_resource_group.rg_core_infra_tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

# Create Storage Container in the Storage Account
resource "azurerm_storage_container" "storage_container_core_infra_tfstate_prod" {
  name                  = "terraform-state-${var.common_name}"
  storage_account_id    = azurerm_storage_account.storage_account_core_infra_tfstate.id
  container_access_type = "container"
}

# Create the core Virtual Network
resource "azurerm_virtual_network" "vnet_core_infra_tfstate" {
  name                = "vnet-${var.common_name}"
  location            = azurerm_resource_group.rg_core_infra_tfstate.location
  resource_group_name = azurerm_resource_group.rg_core_infra_tfstate.name
  address_space       = ["10.20.0.0/16"]
  tags                = local.common_tags
}

# Create Subnet in core VNet for 'prod' environment
resource "azurerm_subnet" "sn_core_infra_prod" {
  name                 = "sn-${var.common_name}-prod"
  resource_group_name  = azurerm_resource_group.rg_core_infra_tfstate.name
  virtual_network_name = azurerm_virtual_network.vnet_core_infra_tfstate.name
  address_prefixes     = ["10.20.1.0/24"]
}

# Create Subnet in core VNet for 'dev' environment
resource "azurerm_subnet" "sn_core_infra_dev" {
  name                 = "sn-${var.common_name}-dev"
  resource_group_name  = azurerm_resource_group.rg_core_infra_tfstate.name
  virtual_network_name = azurerm_virtual_network.vnet_core_infra_tfstate.name
  address_prefixes     = ["10.20.2.0/24"]
}

# Create Subnet in core VNet for the database
resource "azurerm_subnet" "sn_core_infra_db" {
  name                 = "sn-${var.common_name}-cosmosdb"
  resource_group_name  = azurerm_resource_group.rg_core_infra_tfstate.name
  virtual_network_name = azurerm_virtual_network.vnet_core_infra_tfstate.name
  address_prefixes     = ["10.20.3.0/24"]
  service_endpoints    = ["Microsoft.AzureCosmosDB"]
}
