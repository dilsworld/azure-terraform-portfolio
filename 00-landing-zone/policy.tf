# Built-in policy assignments. Assignment names at MG scope are max 24 chars.
# Starts in DoNotEnforce (audit) mode - flip var.policy_enforce once compliance looks clean.

locals {
  builtin = {
    allowed_locations    = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
    allowed_rg_locations = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
    require_tag          = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
    deny_nic_public_ip   = "/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114"
  }
}

# --- Intermediate root: applies to everything ---

resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  display_name         = "Allowed locations"
  management_group_id  = azurerm_management_group.root.id
  policy_definition_id = local.builtin.allowed_locations
  enforce              = var.policy_enforce

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}

resource "azurerm_management_group_policy_assignment" "allowed_rg_locations" {
  name                 = "allowed-rg-locations"
  display_name         = "Allowed locations for resource groups"
  management_group_id  = azurerm_management_group.root.id
  policy_definition_id = local.builtin.allowed_rg_locations
  enforce              = var.policy_enforce

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}

# --- Landing Zones: workload guardrails ---

resource "azurerm_management_group_policy_assignment" "require_tag" {
  name                 = "require-owner-tag"
  display_name         = "Require '${var.required_tag_name}' tag on resources"
  management_group_id  = azurerm_management_group.landingzones.id
  policy_definition_id = local.builtin.require_tag
  enforce              = var.policy_enforce

  parameters = jsonencode({
    tagName = { value = var.required_tag_name }
  })
}

# --- Corp: no public IPs on NICs (traffic goes via the hub) ---

resource "azurerm_management_group_policy_assignment" "deny_nic_public_ip" {
  name                 = "deny-nic-public-ip"
  display_name         = "Network interfaces should not have public IPs"
  management_group_id  = azurerm_management_group.corp.id
  policy_definition_id = local.builtin.deny_nic_public_ip
  enforce              = var.policy_enforce
}
