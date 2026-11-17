# github-oidc.tf - lets GitHub Actions log in to Azure with NO stored secret.
# GitHub presents a short-lived token; Entra ID trusts it only for this repo.

data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}

resource "azuread_application" "gha" {
  display_name = "gha-${var.prefix}-terraform"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "gha" {
  client_id = azuread_application.gha.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

# Which GitHub runs are trusted
locals {
  subject_repo = coalesce(var.github_oidc_subject_repo, var.github_repo)

  github_subjects = {
    pull-requests = "repo:${local.subject_repo}:pull_request"
    main-branch   = "repo:${local.subject_repo}:ref:refs/heads/main"
    production    = "repo:${local.subject_repo}:environment:production"
  }
}

resource "azuread_application_federated_identity_credential" "gha" {
  for_each       = local.github_subjects
  application_id = azuread_application.gha.id
  display_name   = "github-${each.key}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = each.value
}

# Lab: Contributor on the subscription. Production: scope to specific RGs.
resource "azurerm_role_assignment" "gha_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.gha.object_id
}

resource "azurerm_role_assignment" "gha_state" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.gha.object_id
}

# Extra repos (e.g. azure-terraform-portfolio) trusted by the same app
locals {
  extra_subjects = merge([
    for name, repo in var.extra_github_repos : {
      "${name}-pull-requests" = "repo:${repo}:pull_request"
      "${name}-main-branch"   = "repo:${repo}:ref:refs/heads/main"
      "${name}-production"    = "repo:${repo}:environment:production"
    }
  ]...)
}

resource "azuread_application_federated_identity_credential" "gha_extra" {
  for_each       = local.extra_subjects
  application_id = azuread_application.gha.id
  display_name   = "github-${each.key}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = each.value
}
