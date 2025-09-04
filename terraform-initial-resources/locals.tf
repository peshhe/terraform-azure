locals {
  # Common tags to be assigned to all resources
  common_tags = {
    "Owner"              = "Petar Karadzhov"
    "Cost Center"        = "core-infra"
    "Project"            = "Core Infrastructure"
    "Managed By"         = "Terraform"
    "Responsible person" = "Petar Karadzhov"
  }
}