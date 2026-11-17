# variables.tf
variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "uksouth"
}

# Must match the prefix used in ../persistent
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

# Optional: your home IP as x.x.x.x/32 to allow SSH. Leave null = no SSH rule.
variable "ssh_source_cidr" {
  type    = string
  default = null
}

# Public key text. Used by the pipeline (TF_VAR_ssh_public_key).
# Leave null locally and ssh_public_key_path is used instead.
variable "ssh_public_key" {
  type    = string
  default = null
}
