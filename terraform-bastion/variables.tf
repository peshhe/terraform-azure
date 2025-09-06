variable "common_name" {
  type        = string
  description = "The common name of all the Resources to be created."
  default     = "bastion"
}

variable "subscription_id" { # will be set by CI/CD
  type        = string
  description = "Azure Subscription's ID."
}

variable "admin_username" { # will be set by CI/CD
  type        = string
  description = "The username used for admin access to the VMs."
  sensitive   = true
}

variable "admin_password" { # will be set by CI/CD
  type        = string
  description = "The admin's password for the VMs."
  sensitive   = true
}

variable "allowed_ip_address" { # will be set by CI/CD
  type        = string
  description = "The IP address that would have SSH access to the bastion."
  sensitive   = true
}
