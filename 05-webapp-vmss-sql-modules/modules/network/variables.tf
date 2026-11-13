variable "project_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "web_subnet_prefix" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "data_subnet_prefix" {
  type    = list(string)
  default = ["10.0.2.0/24"]
}