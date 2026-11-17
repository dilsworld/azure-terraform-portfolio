# Hub network in the connectivity subscription.

resource "azurerm_resource_group" "connectivity" {
  provider = azurerm.connectivity
  name     = "rg-${var.org_prefix}-connectivity-${var.location}"
  location = var.location
  tags     = var.default_tags
}

resource "azurerm_virtual_network" "hub" {
  provider            = azurerm.connectivity
  name                = "vnet-${var.org_prefix}-hub-${var.location}"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  address_space       = [var.hub_address_space]
  tags                = var.default_tags
}

# Carve the hub /22 into well-known subnets.
locals {
  hub_subnets = {
    AzureFirewallSubnet           = cidrsubnet(var.hub_address_space, 4, 0) # /26
    AzureFirewallManagementSubnet = cidrsubnet(var.hub_address_space, 4, 1) # /26 (needed for Basic SKU)
    GatewaySubnet                 = cidrsubnet(var.hub_address_space, 5, 4) # /27
    AzureBastionSubnet            = cidrsubnet(var.hub_address_space, 4, 3) # /26
    snet-shared                   = cidrsubnet(var.hub_address_space, 2, 1) # /24 shared services (DNS, jump hosts)
  }
}

resource "azurerm_subnet" "hub" {
  provider             = azurerm.connectivity
  for_each             = local.hub_subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [each.value]
}

# ---------- Optional Azure Firewall (Basic) ----------

resource "azurerm_public_ip" "firewall" {
  provider            = azurerm.connectivity
  count               = var.deploy_firewall ? 1 : 0
  name                = "pip-${var.org_prefix}-afw-${var.location}"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.default_tags
}

resource "azurerm_public_ip" "firewall_mgmt" {
  provider            = azurerm.connectivity
  count               = var.deploy_firewall ? 1 : 0
  name                = "pip-${var.org_prefix}-afw-mgmt-${var.location}"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.default_tags
}

resource "azurerm_firewall_policy" "hub" {
  provider            = azurerm.connectivity
  count               = var.deploy_firewall ? 1 : 0
  name                = "afwp-${var.org_prefix}-hub-${var.location}"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  sku                 = "Basic"
  tags                = var.default_tags
}

# Example rule: allow spokes to reach each other and Windows Update / Ubuntu repos.
resource "azurerm_firewall_policy_rule_collection_group" "baseline" {
  provider           = azurerm.connectivity
  count              = var.deploy_firewall ? 1 : 0
  name               = "rcg-baseline"
  firewall_policy_id = azurerm_firewall_policy.hub[0].id
  priority           = 200

  network_rule_collection {
    name     = "spoke-to-spoke"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-spokes"
      protocols             = ["Any"]
      source_addresses      = [for s in var.spokes : s.address_space]
      destination_addresses = [for s in var.spokes : s.address_space]
      destination_ports     = ["*"]
    }
  }

  application_rule_collection {
    name     = "os-updates"
    priority = 200
    action   = "Allow"

    rule {
      name = "allow-updates"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses  = [for s in var.spokes : s.address_space]
      destination_fqdns = ["*.windowsupdate.com", "*.update.microsoft.com", "*.delivery.mp.microsoft.com"]
    }

    rule {
      name = "allow-ubuntu"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses  = [for s in var.spokes : s.address_space]
      destination_fqdns = ["*.ubuntu.com", "*.canonical.com"]
    }
  }
}

resource "azurerm_firewall" "hub" {
  provider            = azurerm.connectivity
  count               = var.deploy_firewall ? 1 : 0
  name                = "afw-${var.org_prefix}-hub-${var.location}"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  firewall_policy_id  = azurerm_firewall_policy.hub[0].id
  tags                = var.default_tags

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.hub["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }

  management_ip_configuration {
    name                 = "mgmt-ipconfig"
    subnet_id            = azurerm_subnet.hub["AzureFirewallManagementSubnet"].id
    public_ip_address_id = azurerm_public_ip.firewall_mgmt[0].id
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  provider                       = azurerm.connectivity
  count                          = var.deploy_firewall ? 1 : 0
  name                           = "diag-afw-to-law"
  target_resource_id             = azurerm_firewall.hub[0].id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.central.id
  log_analytics_destination_type = "Dedicated"

  enabled_log { category_group = "allLogs" }
}

# ---------- Private DNS for Private Endpoints ----------

resource "azurerm_private_dns_zone" "zones" {
  provider            = azurerm.connectivity
  for_each            = toset(var.private_dns_zones)
  name                = each.value
  resource_group_name = azurerm_resource_group.connectivity.name
  tags                = var.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  provider              = azurerm.connectivity
  for_each              = azurerm_private_dns_zone.zones
  name                  = "link-hub"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = var.default_tags
}
