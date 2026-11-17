# variables.tf

# Where the "production" VM runs
variable "primary_location" {
  type    = string
  default = "uksouth"
}

# Where it fails over to (and where the Recovery Services vault lives)
variable "secondary_location" {
  type    = string
  default = "ukwest"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s_v2"
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

variable "tags" {
  type = map(string)
  default = {
    owner       = "dylan"
    environment = "lab"
    workload    = "dr-demo"
    managed_by  = "terraform"
  }
}
