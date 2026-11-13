# nsg.tf
resource "azurerm_network_security_group" "workload" {
  for_each            = local.spokes
  name                = "nsg-${var.prefix}-${each.key}-workload"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  security_rule {
    name                       = "Allow-SSH-From-Bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.bastion_subnet
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-SSH-Other-VNet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "workload" {
  for_each                  = local.spokes
  subnet_id                 = azurerm_subnet.workload[each.key].id
  network_security_group_id = azurerm_network_security_group.workload[each.key].id
}