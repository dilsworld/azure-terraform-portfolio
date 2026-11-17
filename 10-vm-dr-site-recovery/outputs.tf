output "vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}

output "recovery_vault" {
  value = azurerm_recovery_services_vault.dr.name
}

output "replicated_item" {
  value = azurerm_site_recovery_replicated_vm.app01.name
}

output "ip_plan" {
  description = "Where the VM lives in each scenario"
  value = {
    primary_uksouth      = "10.20.0.10"
    failover_ukwest      = "10.21.0.10"
    test_failover_ukwest = "10.22.0.10"
  }
}
