output "management_group_ids" {
  description = "IDs of every management group in the hierarchy."
  value       = local.mg_ids
}

output "log_analytics_workspace_id" {
  description = "Central Log Analytics workspace resource ID."
  value       = azurerm_log_analytics_workspace.central.id
}

output "hub_vnet_id" {
  description = "Hub VNet resource ID."
  value       = azurerm_virtual_network.hub.id
}

output "spoke_vnet_ids" {
  description = "Spoke VNet resource IDs."
  value       = { for k, v in azurerm_virtual_network.spoke : k => v.id }
}

output "spoke_subnet_ids" {
  description = "Spoke subnet IDs keyed \"<spoke>/<subnet>\" - workload/server deployments use these."
  value       = { for k, v in azurerm_subnet.spoke : k => v.id }
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP (null if not deployed)."
  value       = var.deploy_firewall ? azurerm_firewall.hub[0].ip_configuration[0].private_ip_address : null
}
