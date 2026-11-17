# Three networks:
#   primary   - UK South, where the VM normally runs
#   recovery  - UK West, where it lands after a real failover
#   test      - UK West, isolated (no peering) for test failovers that
#               must never clash with the live VM
# Ranges avoid the landing zone (10.0-10.2) and lab 06 (10.0.0.0/16).

resource "azurerm_resource_group" "primary" {
  name     = "rg-dr-primary-${var.primary_location}"
  location = var.primary_location
  tags     = var.tags
}

resource "azurerm_resource_group" "secondary" {
  name     = "rg-dr-secondary-${var.secondary_location}"
  location = var.secondary_location
  tags     = var.tags
}

# ---------- Primary ----------

resource "azurerm_virtual_network" "primary" {
  name                = "vnet-dr-primary"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  address_space       = ["10.20.0.0/24"]
  tags                = var.tags
}

resource "azurerm_subnet" "primary" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.primary.name
  virtual_network_name = azurerm_virtual_network.primary.name
  address_prefixes     = ["10.20.0.0/26"]
}

# ---------- Recovery (real failover target) ----------
# Same subnet name and a matching range, so the VM keeps a familiar address.

resource "azurerm_virtual_network" "recovery" {
  name                = "vnet-dr-recovery"
  location            = azurerm_resource_group.secondary.location
  resource_group_name = azurerm_resource_group.secondary.name
  address_space       = ["10.21.0.0/24"]
  tags                = var.tags
}

resource "azurerm_subnet" "recovery" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.secondary.name
  virtual_network_name = azurerm_virtual_network.recovery.name
  address_prefixes     = ["10.21.0.0/26"]
}

# ---------- Test failover (isolated) ----------

resource "azurerm_virtual_network" "test" {
  name                = "vnet-dr-test"
  location            = azurerm_resource_group.secondary.location
  resource_group_name = azurerm_resource_group.secondary.name
  address_space       = ["10.22.0.0/24"]
  tags                = var.tags
}

resource "azurerm_subnet" "test" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.secondary.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.22.0.0/26"]
}

# ---------- NSG (no inbound from internet; outbound left open so the
# Site Recovery mobility agent can reach Azure) ----------

resource "azurerm_network_security_group" "primary" {
  name                = "nsg-dr-primary-app"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "primary" {
  subnet_id                 = azurerm_subnet.primary.id
  network_security_group_id = azurerm_network_security_group.primary.id
}
