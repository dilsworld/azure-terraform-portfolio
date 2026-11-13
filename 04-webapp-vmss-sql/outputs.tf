output "load_balancer_public_ip" {
  value = azurerm_public_ip.lb.ip_address
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.law.workspace_id
}
