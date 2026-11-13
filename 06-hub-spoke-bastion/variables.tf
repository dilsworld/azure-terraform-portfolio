# variables.tf
variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "uksouth"
}

variable "prefix" {
  type    = string
  default = "lab"
}

variable "vm_size" {
  type    = string
  default = "Standard_E2s_v7"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}