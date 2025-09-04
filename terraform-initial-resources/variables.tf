variable "location" {
  type        = string
  description = "The location of the Resources to be created in."
}

variable "common_name" {
  type        = string
  description = "The common name of all the Resources to be created."
  default     = "assignment"
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription's ID."
}

variable "storage_account_name" {
  type        = string
  description = "Azure Storage Account's name."
}
