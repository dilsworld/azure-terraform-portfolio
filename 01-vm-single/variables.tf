# variables.tf

variable "location" {
  type    = string
  default = "ukwest"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s_v2"
}

# Your home IP as x.x.x.x/32 to allow SSH. Null or "" = no SSH rule.
variable "ssh_source_cidr" {
  type    = string
  default = null
}

# Public key text. Set by the pipeline (TF_VAR_ssh_public_key).
# Leave null locally and ssh_public_key_path is used instead.
variable "ssh_public_key" {
  type    = string
  default = null
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
