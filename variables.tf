variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "esmos-healthcare-rg"
}

variable "location" {
  description = "The Azure region to deploy resources in"
  type        = string
  default     = "southeastasia"
}

variable "db_admin_user" {
  description = "The PostgreSQL Admin Username"
  type        = string
  default     = "esmosadmin"
}

variable "db_admin_password" {
  description = "The PostgreSQL Admin Password"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd1234!"
}
