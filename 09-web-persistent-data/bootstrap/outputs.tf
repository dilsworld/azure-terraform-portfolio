# outputs.tf - copy these into GitHub: Settings > Secrets and variables > Actions
output "AZURE_CLIENT_ID" {
  value = azuread_application.gha.client_id
}

output "AZURE_TENANT_ID" {
  value = data.azurerm_client_config.current.tenant_id
}

output "AZURE_SUBSCRIPTION_ID" {
  value = data.azurerm_subscription.current.subscription_id
}

output "state_storage_account" {
  value = azurerm_storage_account.tfstate.name
}
