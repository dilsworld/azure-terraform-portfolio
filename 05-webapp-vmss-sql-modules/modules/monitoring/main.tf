resource "azurerm_log_analytics_workspace" "log" {
  name                = "log-${var.project_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "lb" {
  name                       = "diag-lb"
  target_resource_id         = var.load_balancer_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log.id

  enabled_log {
    category = "LoadBalancerHealthEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}