variable "project_name" {
  description = "Short name used to prefix resources"
  type        = string
  default     = "webapp-prod"
}

variable "location" {
  description = "Azure region to deploy into"
  type        = string
  default     = "ukwest"
}

variable "vm_size" {
  description = "VM size for the web tier scale set"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "admin_username" {
  description = "Admin username for the web tier VMs"
  type        = string
  default     = "azureadmin"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for VM access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "sql_admin_username" {
  description = "Admin username for the Azure SQL logical server"
  type        = string
  default     = "sqladmin"
}

variable "vmss_instance_count" {
  description = "Starting instance count for the web tier scale set"
  type        = number
  default     = 2
}