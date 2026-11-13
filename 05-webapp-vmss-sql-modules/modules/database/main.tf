resource "random_password" "sql_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_mssql_server" "sql" {
  name                         = "sql-${var.project_name}-${var.random_suffix}"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = random_password.sql_password.result
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_database" "db" {
  name      = "sqldb-${var.project_name}"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "S0"
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-${var.project_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.data_subnet_id

  private_service_connection {
    name                           = "psc-sql"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }
}

output "database_id" {
  value = azurerm_mssql_database.db.id
}

output "sql_admin_password" {
  value     = random_password.sql_password.result
  sensitive = true
}