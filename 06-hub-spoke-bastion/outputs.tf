# outputs.tf
output "vm_private_ips" {
  value = { for k, nic in azurerm_network_interface.vm : k => nic.private_ip_address }
}