resource "azurerm_resource_group" "arc" {
  name     = "rg-${var.prefix}-arc"
  location = var.location
  tags     = { purpose = "lab" }
}

resource "azurerm_log_analytics_workspace" "lab" {
  name                = "law-${var.prefix}-arc"
  location            = azurerm_resource_group.arc.location
  resource_group_name = azurerm_resource_group.arc.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.5
}
