output "cosmosdb-endpoint" {
  description = "The endpoint used to connect to the CosmosDB account."
  value       = azurerm_cosmosdb_account.cosmosdb_account_main.endpoint
}

output "cosmosdb-primary_key" {
  description = "The Primary key for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.cosmosdb_account_main.primary_key
  sensitive   = true
}

output "lb-public_ip" {
  description = "The Load Balancer's Public IP - to access the webserver VM(s)."
  value       = azurerm_public_ip.terraform_public_ip_lb.ip_address
}
