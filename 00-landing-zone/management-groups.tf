# CAF-style hierarchy:
#
# Tenant Root Group
# └── <prefix>                 (intermediate root)
#     ├── platform
#     │   ├── management
#     │   ├── connectivity
#     │   └── identity
#     ├── landingzones
#     │   ├── corp             (private, connected to hub)
#     │   └── online           (internet-facing)
#     ├── sandbox
#     └── decommissioned

locals {
  tenant_root_mg_id = "/providers/Microsoft.Management/managementGroups/${data.azurerm_client_config.current.tenant_id}"
}

resource "azurerm_management_group" "root" {
  name                       = var.org_prefix
  display_name               = upper(var.org_prefix)
  parent_management_group_id = local.tenant_root_mg_id
}

# Level 1
resource "azurerm_management_group" "platform" {
  name                       = "${var.org_prefix}-platform"
  display_name               = "Platform"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "landingzones" {
  name                       = "${var.org_prefix}-landingzones"
  display_name               = "Landing Zones"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "sandbox" {
  name                       = "${var.org_prefix}-sandbox"
  display_name               = "Sandbox"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "decommissioned" {
  name                       = "${var.org_prefix}-decommissioned"
  display_name               = "Decommissioned"
  parent_management_group_id = azurerm_management_group.root.id
}

# Level 2 - Platform
resource "azurerm_management_group" "management" {
  name                       = "${var.org_prefix}-management"
  display_name               = "Management"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "connectivity" {
  name                       = "${var.org_prefix}-connectivity"
  display_name               = "Connectivity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "identity" {
  name                       = "${var.org_prefix}-identity"
  display_name               = "Identity"
  parent_management_group_id = azurerm_management_group.platform.id
}

# Level 2 - Landing Zones
resource "azurerm_management_group" "corp" {
  name                       = "${var.org_prefix}-corp"
  display_name               = "Corp"
  parent_management_group_id = azurerm_management_group.landingzones.id
}

resource "azurerm_management_group" "online" {
  name                       = "${var.org_prefix}-online"
  display_name               = "Online"
  parent_management_group_id = azurerm_management_group.landingzones.id
}

# Lookup map used by policy, RBAC and subscription placement
locals {
  mg_ids = {
    root           = azurerm_management_group.root.id
    platform       = azurerm_management_group.platform.id
    landingzones   = azurerm_management_group.landingzones.id
    sandbox        = azurerm_management_group.sandbox.id
    decommissioned = azurerm_management_group.decommissioned.id
    management     = azurerm_management_group.management.id
    connectivity   = azurerm_management_group.connectivity.id
    identity       = azurerm_management_group.identity.id
    corp           = azurerm_management_group.corp.id
    online         = azurerm_management_group.online.id
  }
}

# Move subscriptions into the hierarchy
resource "azurerm_management_group_subscription_association" "placement" {
  for_each = var.subscription_placement

  management_group_id = local.mg_ids[each.value]
  subscription_id     = "/subscriptions/${each.key}"
}
