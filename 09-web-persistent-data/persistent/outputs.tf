# outputs.tf
output "data_disk_id" {
  value = azurerm_managed_disk.webdata.id
}

output "public_ip" {
  value = azurerm_public_ip.web.ip_address
}
