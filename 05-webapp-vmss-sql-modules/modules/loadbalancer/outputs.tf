output "lb_id" {
  value = azurerm_lb.lb.id
}

output "lb_backend_address_pool_id" {
  value = azurerm_lb_backend_address_pool.bepool.id
}