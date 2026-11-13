resource "random_password" "sql_admin" {
  length      = 20
  special     = true
  min_special = 2
}

resource "azurerm_key_vault" "kv" {
  name                = "kv-${var.project_name}-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Access policy for the person/service running Terraform, so it can
  # write the secret below.
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "Set", "List", "Delete", "Purge"]
  }

  # Access policy for the web tier's managed identity, so the app can
  # read the secret at runtime without any credential in the image.
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_virtual_machine_scale_set.web.identity[0].principal_id

    secret_permissions = ["Get", "List"]
  }
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin.result
  key_vault_id = azurerm_key_vault.kv.id
}
