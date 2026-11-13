variable "subscription_id" {
  description = "Azure subscription ID to deploy into"
  type        = string
}

variable "prefix" {
  description = "Prefix used for naming resources"
  type        = string
  default     = "demo"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "uksouth"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version (null = AKS default)"
  type        = string
  default     = null
}

variable "system_node_vm_size" {
  type    = string
  default = "Standard_D2s_v6"
}

variable "system_node_min" {
  type    = number
  default = 1
}

variable "system_node_max" {
  type    = number
  default = 2
}

variable "user_node_vm_size" {
  type    = string
  default = "Standard_D2s_v6"
}

variable "user_node_min" {
  type    = number
  default = 1
}

variable "user_node_max" {
  type    = number
  default = 2
}

variable "admin_group_object_ids" {
  description = "Entra ID group object IDs granted cluster-admin"
  type        = list(string)
  default     = []
}

variable "api_authorized_ip_ranges" {
  description = "CIDRs allowed to reach the API server (empty = open)"
  type        = list(string)
  default     = []
}

variable "tags" {
  type = map(string)
  default = {
    managed_by = "terraform"
    workload   = "aks"
  }
}
