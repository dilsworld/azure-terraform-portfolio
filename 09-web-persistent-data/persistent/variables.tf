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

variable "data_disk_size_gb" {
  type    = number
  default = 32
}
