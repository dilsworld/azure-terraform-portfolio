# main.tf
# WEB LAYER - disposable. destroy/apply as often as you like.

# Look up the persistent resources (created in ../persistent)
data "azurerm_resource_group" "data" {
  name = "rg-${var.prefix}-web-data"
}

data "azurerm_managed_disk" "webdata" {
  name                = "disk-${var.prefix}-web-data"
  resource_group_name = data.azurerm_resource_group.data.name
}

data "azurerm_public_ip" "web" {
  name                = "pip-${var.prefix}-web"
  resource_group_name = data.azurerm_resource_group.data.name
}

resource "azurerm_resource_group" "web" {
  name     = "rg-${var.prefix}-web"
  location = var.location
  tags     = { purpose = "lab", layer = "web" }
}
