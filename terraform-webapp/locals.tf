locals {
  # Common tags to be assigned to all resources
  common_tags = {
    "Owner"              = "Petar Karadzhov"
    "Cost Center"        = "webapp-${var.environment}"
    "Project"            = "WebApp with DB and LB"
    "Managed By"         = "Terraform"
    "Responsible person" = "Petar Karadzhov"
  }
}