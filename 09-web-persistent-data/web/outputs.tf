# outputs.tf
output "url" {
  value = "http://${data.azurerm_public_ip.web.ip_address}"
}

output "rebuild_history" {
  value = "http://${data.azurerm_public_ip.web.ip_address}/rebuilds.txt"
}
