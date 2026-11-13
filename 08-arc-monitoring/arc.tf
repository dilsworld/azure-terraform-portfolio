# Looks up each Arc-enabled server by its hostname
data "azurerm_arc_machine" "linux" {
  for_each            = toset(var.arc_linux_machines)
  name                = each.key
  resource_group_name = azurerm_resource_group.arc.name
}

# Installs the Azure Monitor Agent on each server
resource "azurerm_arc_machine_extension" "ama" {
  for_each                  = toset(var.arc_linux_machines)
  name                      = "AzureMonitorLinuxAgent"
  location                  = var.location
  arc_machine_id            = data.azurerm_arc_machine.linux[each.key].id
  publisher                 = "Microsoft.Azure.Monitor"
  type                      = "AzureMonitorLinuxAgent"
  automatic_upgrade_enabled = true
}

# Links each server to the data collection rule
resource "azurerm_monitor_data_collection_rule_association" "linux" {
  for_each                = toset(var.arc_linux_machines)
  name                    = "dcra-${each.key}"
  target_resource_id      = data.azurerm_arc_machine.linux[each.key].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.linux.id
  depends_on              = [azurerm_arc_machine_extension.ama]
}
