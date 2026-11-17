# main.tf
# PERSISTENT LAYER - deploy once, leave running.
# Holds everything that must survive the web server being destroyed.

resource "azurerm_resource_group" "data" {
  name     = "rg-${var.prefix}-web-data"
  location = var.location
  tags     = { purpose = "lab", layer = "persistent" }
}

# The data disk - site content and anything stateful lives here
resource "azurerm_managed_disk" "webdata" {
  name                 = "disk-${var.prefix}-web-data"
  location             = azurerm_resource_group.data.location
  resource_group_name  = azurerm_resource_group.data.name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  tags                 = { purpose = "lab", layer = "persistent" }

  lifecycle {
    prevent_destroy = true
  }
}

# Static public IP - the web server comes back on the same address
resource "azurerm_public_ip" "web" {
  name                = "pip-${var.prefix}-web"
  location            = azurerm_resource_group.data.location
  resource_group_name = azurerm_resource_group.data.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = { purpose = "lab", layer = "persistent" }

  lifecycle {
    prevent_destroy = true
  }
}

# Delete lock - stops the resource group (and the disk/IP in it) being
# deleted from the portal or az CLI. Remove this before tearing down.
resource "azurerm_management_lock" "data" {
  name       = "lock-web-data"
  scope      = azurerm_resource_group.data.id
  lock_level = "CanNotDelete"
  notes      = "Protects persistent web data disk and static IP"

  depends_on = [azurerm_managed_disk.webdata, azurerm_public_ip.web]
}
