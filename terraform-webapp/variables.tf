variable "subscription_id" { # will be set by CI/CD
  type        = string
  description = "Azure Subscription's ID."
}

variable "location" {
  type        = string
  description = "The location of the Resources to be created in."
}

variable "environment" { # will be set dynamically by CI/CD
  type        = string
  description = "The short-name of the environment to be created."
}

variable "common_name" {
  type        = string
  description = "The common name of all the Resources to be created."
  default     = "assignment"
}

variable "allowed_ip_address" { # will be set by CI/CD
  type        = string
  description = "The IP address that would have access to the Cosmos DB."
  sensitive   = true
}

variable "admin_username" { # will be set by CI/CD
  type        = string
  description = "Admin account's username for the VMs."
  sensitive   = true
}

variable "admin_password" { # will be set by CI/CD
  type        = string
  description = "The password for the admin account."
  sensitive   = true
}

variable "number_of_instances" { # will be set by CI/CD
  type        = string
  description = "The number of how much instances (VMs) are needed."
}

variable "slack_url" { # will be set by CI/CD
  type        = string
  description = "Webhook URL for Slack notifications."
  sensitive   = true
}
