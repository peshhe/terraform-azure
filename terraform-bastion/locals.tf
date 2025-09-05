locals {
  # Common tags to be assigned to all resources
  common_tags = {
    "Owner"              = "Petar Karadzhov"
    "Cost Center"        = "bastion"
    "Project"            = "Azure Bastion"
    "Managed By"         = "Terraform"
    "Responsible person" = "Petar Karadzhov"
  }
}