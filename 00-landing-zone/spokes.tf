# Spoke VNets in the landing zone subscription, peered to the hub.
# If the firewall is deployed, spoke subnets route 0.0.0.0/0 through it.

locals {
  spoke_subnets = merge([
    for spoke_key, spoke in var.spokes : {
      for subnet_name, cidr in spoke.subnets :
      "${spoke_key}/${subnet_name}" => {
        spoke  = spoke_key
        name   = subnet_name
        prefix = cidr
      }
    }
  ]...)
}

resource "azurerm_resource_group" "spoke" {
  provider = azurerm.landingzone
  for_each = var.spokes
  name     = "rg-${var.org_prefix}-${each.key}-network-${var.location}"
  location = var.location
  tags     = var.default_tags
}

resource "azurerm_virtual_network" "spoke" {
  provider            = azurerm.landingzone
  for_each            = var.spokes
  name                = "vnet-${var.org_prefix}-${each.key}-${var.location}"
  location            = azurerm_resource_group.spoke[each.key].location
  resource_group_name = azurerm_resource_group.spoke[each.key].name
  address_space       = [each.value.address_space]
  tags                = var.default_tags
}

resource "azurerm_subnet" "spoke" {
  provider             = azurerm.landingzone
  for_each             = local.spoke_subnets
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.spoke[each.value.spoke].name
  virtual_network_name = azurerm_virtual_network.spoke[each.value.spoke].name
  address_prefixes     = [each.value.prefix]
}

# Basic NSG per subnet (deny inbound from internet is the Azure default;
# add rules per workload as needed).
resource "azurerm_network_security_group" "spoke" {
  provider            = azurerm.landingzone
  for_each            = local.spoke_subnets
  name                = "nsg-${replace(each.key, "/", "-")}"
  location            = azurerm_resource_group.spoke[each.value.spoke].location
  resource_group_name = azurerm_resource_group.spoke[each.value.spoke].name
  tags                = var.default_tags
}

resource "azurerm_subnet_network_security_group_association" "spoke" {
  provider                  = azurerm.landingzone
  for_each                  = local.spoke_subnets
  subnet_id                 = azurerm_subnet.spoke[each.key].id
  network_security_group_id = azurerm_network_security_group.spoke[each.key].id
}

# ---------- Peering (both directions) ----------

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider                  = azurerm.connectivity
  for_each                  = var.spokes
  name                      = "peer-hub-to-${each.key}"
  resource_group_name       = azurerm_resource_group.connectivity.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke[each.key].id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false # set true once a VPN/ER gateway exists in the hub
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  provider                  = azurerm.landingzone
  for_each                  = var.spokes
  name                      = "peer-${each.key}-to-hub"
  resource_group_name       = azurerm_resource_group.spoke[each.key].name
  virtual_network_name      = azurerm_virtual_network.spoke[each.key].name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false # set true once a hub gateway exists
}

# Let spokes resolve the Private Endpoint DNS zones held in the hub.
locals {
  zone_spoke_links = merge([
    for zone in var.private_dns_zones : {
      for spoke_key in keys(var.spokes) :
      "${zone}|${spoke_key}" => { zone = zone, spoke = spoke_key }
    }
  ]...)
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  provider              = azurerm.connectivity
  for_each              = local.zone_spoke_links
  name                  = "link-${each.value.spoke}"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.value.zone].name
  virtual_network_id    = azurerm_virtual_network.spoke[each.value.spoke].id
  registration_enabled  = false
  tags                  = var.default_tags
}

# ---------- Force-tunnel spokes via the firewall ----------

resource "azurerm_route_table" "spoke" {
  provider                      = azurerm.landingzone
  for_each                      = var.deploy_firewall ? var.spokes : {}
  name                          = "rt-${var.org_prefix}-${each.key}-${var.location}"
  location                      = azurerm_resource_group.spoke[each.key].location
  resource_group_name           = azurerm_resource_group.spoke[each.key].name
  bgp_route_propagation_enabled = false
  tags                          = var.default_tags

  route {
    name                   = "default-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub[0].ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "spoke" {
  provider       = azurerm.landingzone
  for_each       = var.deploy_firewall ? local.spoke_subnets : {}
  subnet_id      = azurerm_subnet.spoke[each.key].id
  route_table_id = azurerm_route_table.spoke[each.value.spoke].id
}
