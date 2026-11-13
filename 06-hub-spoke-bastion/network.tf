# network.tf
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.prefix}-hub"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.bastion_subnet]
}

resource "azurerm_virtual_network" "spoke" {
  for_each            = local.spokes
  name                = "vnet-${var.prefix}-${each.key}"
  address_space       = [each.value.address_space]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
}

resource "azurerm_subnet" "workload" {
  for_each             = local.spokes
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.spoke[each.key].name
  address_prefixes     = [each.value.subnet]
}