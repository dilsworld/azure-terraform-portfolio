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

# Hostnames of Linux servers already onboarded to Arc (filled in at Step 3)
variable "arc_linux_machines" {
  type    = list(string)
  default = []
}
