resource "azurerm_log_analytics_workspace" "law" {
  name                = "log-${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "lb" {
  name                       = "diag-lb"
  target_resource_id         = azurerm_lb.web.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "sql" {
  name                       = "diag-sql"
  target_resource_id         = azurerm_mssql_database.db.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "SQLInsights"
  }

  enabled_metric {
    category = "Basic"
  }
}
