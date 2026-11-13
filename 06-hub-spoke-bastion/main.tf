# main.tf
resource "azurerm_resource_group" "lab" {
  name     = "rg-${var.prefix}-hubspoke"
  location = var.location
  tags     = { purpose = "lab" }
}

locals {
  spokes = {
    spoke1 = { address_space = "10.1.0.0/16", subnet = "10.1.1.0/24" }
    spoke2 = { address_space = "10.2.0.0/16", subnet = "10.2.1.0/24" }
  }
  bastion_subnet = "10.0.1.0/26"
}