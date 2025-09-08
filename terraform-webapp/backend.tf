terraform {
  backend "azurerm" {
    resource_group_name  = "rg-sandbox-assignment-core-infra"
    storage_account_name = "sa0demo1tfstate"
    container_name       = "terraform-state-assignment"
    # 'key' will be set dynamically from CI/CD (in format '${var.environment}-environment.tfstate')
  }
}