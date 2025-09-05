output "bastion-ip" {
  description = "The IP address that the bastion VM would be accessible for SSH."
  value       = azurerm_public_ip.terraform_public_ip_bastion.ip_address
}
