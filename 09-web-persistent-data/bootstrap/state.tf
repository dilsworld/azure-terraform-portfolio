# state.tf - remote state storage for the persistent and web layers

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-${var.prefix}-tfstate"
  location = var.location
  tags     = { purpose = "lab", layer = "bootstrap" }
}

# Storage account names must be globally unique
resource "random_string" "sa" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "sttfstate${random_string.sa.result}"
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = { purpose = "lab", layer = "bootstrap" }

  # Versioning = every state change is kept, so a bad apply can be rolled back
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# You (running locally) can read/write state using your Entra ID login
resource "azurerm_role_assignment" "me_state" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Writes backend.hcl into each layer so 'terraform init' knows where state lives
resource "local_file" "backend" {
  for_each = {
    persistent = "09-web/persistent.tfstate"
    web        = "09-web/web.tfstate"
  }
  filename = "${path.module}/../${each.key}/backend.hcl"
  content  = <<-EOT
    resource_group_name  = "${azurerm_resource_group.tfstate.name}"
    storage_account_name = "${azurerm_storage_account.tfstate.name}"
    container_name       = "${azurerm_storage_container.tfstate.name}"
    key                  = "${each.value}"
    use_azuread_auth     = true
  EOT
}
