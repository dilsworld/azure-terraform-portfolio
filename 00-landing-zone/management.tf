# Central logging and security for the platform.

resource "azurerm_resource_group" "management" {
  name     = "rg-${var.org_prefix}-management-${var.location}"
  location = var.location
  tags     = var.default_tags
}

resource "azurerm_log_analytics_workspace" "central" {
  name                = "log-${var.org_prefix}-central-${var.location}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.default_tags
}

# Send the management subscription's Activity Log to the central workspace.
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "diag-activitylog-to-law"
  target_resource_id         = "/subscriptions/${var.management_subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  enabled_log { category = "Administrative" }
  enabled_log { category = "Security" }
  enabled_log { category = "Policy" }
  enabled_log { category = "ServiceHealth" }
  enabled_log { category = "Alert" }
  enabled_log { category = "Recommendation" }
  enabled_log { category = "Autoscale" }
  enabled_log { category = "ResourceHealth" }
}

# Defender for Cloud - off by default because it is billed per resource.
resource "azurerm_security_center_subscription_pricing" "defender" {
  for_each = var.enable_defender ? toset(["VirtualMachines", "StorageAccounts", "KeyVaults", "Arm"]) : toset([])

  tier          = "Standard"
  resource_type = each.value
}
