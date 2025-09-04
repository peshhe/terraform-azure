output "rg-core-infra-name" {
  description = "The name of the Resource Group that contains the core infra."
  value       = azurerm_resource_group.rg_core_infra_tfstate.name
}

output "rg-core-infra-location" {
  description = "The location of the Resource Group that contains the core infra."
  value       = azurerm_resource_group.rg_core_infra_tfstate.location
}

output "vnet-core-infra-id" {
  description = "The id of the core Virtual Network."
  value       = azurerm_virtual_network.vnet_core_infra_tfstate.id
}
