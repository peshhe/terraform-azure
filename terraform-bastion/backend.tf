terraform {
  backend "azurerm" {
    resource_group_name  = "rg-sandbox-assignment-core-infra"
    storage_account_name = "sa0demo1tfstate"
    container_name       = "terraform-state-assignment"
    key                  = "bastion.tfstate"
  }
}