resource "azurerm_mssql_server" "sql" {
  name                         = "sql-${var.project_name}-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = random_password.sql_admin.result

  # No public network access - the only path in is the private endpoint
  # below, from the data subnet.
  public_network_access_enabled = false
}

resource "azurerm_mssql_database" "db" {
  name        = "sqldb-${var.project_name}"
  server_id   = azurerm_mssql_server.sql.id
  sku_name    = "S0"
  max_size_gb = 5
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-${var.project_name}-sql"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.data.id

  private_service_connection {
    name                           = "sql-connection"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}
