# Azure Site Recovery: replicate vm-dr-app01 from UK South to UK West.
#
# Building blocks (same model as VMware SRM / on-prem DR):
#   vault         - the DR control plane, lives in the TARGET region
#   fabrics       - one per region
#   containers    - one per fabric, hold the protected items
#   policy        - how often recovery points are taken / kept (RPO)
#   mappings      - which container replicates to which, and which network
#                   maps to which
#   cache storage - staging account in the SOURCE region; changes land here
#                   before being shipped across
#   replicated vm - the protected item itself

resource "azurerm_recovery_services_vault" "dr" {
  name                = "rsv-dr-${var.secondary_location}"
  location            = azurerm_resource_group.secondary.location
  resource_group_name = azurerm_resource_group.secondary.name
  sku                 = "Standard"
  soft_delete_enabled = false # lab only - makes destroy clean
  tags                = var.tags
}

# ---------- Fabrics ----------

resource "azurerm_site_recovery_fabric" "primary" {
  name                = "fabric-${var.primary_location}"
  resource_group_name = azurerm_resource_group.secondary.name
  recovery_vault_name = azurerm_recovery_services_vault.dr.name
  location            = azurerm_resource_group.primary.location
}

resource "azurerm_site_recovery_fabric" "secondary" {
  name                = "fabric-${var.secondary_location}"
  resource_group_name = azurerm_resource_group.secondary.name
  recovery_vault_name = azurerm_recovery_services_vault.dr.name
  location            = azurerm_resource_group.secondary.location
}

# ---------- Protection containers ----------

resource "azurerm_site_recovery_protection_container" "primary" {
  name                 = "container-${var.primary_location}"
  resource_group_name  = azurerm_resource_group.secondary.name
  recovery_vault_name  = azurerm_recovery_services_vault.dr.name
  recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
}

resource "azurerm_site_recovery_protection_container" "secondary" {
  name                 = "container-${var.secondary_location}"
  resource_group_name  = azurerm_resource_group.secondary.name
  recovery_vault_name  = azurerm_recovery_services_vault.dr.name
  recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name
}

# ---------- Replication policy (RPO / retention) ----------

resource "azurerm_site_recovery_replication_policy" "policy" {
  name                                                 = "policy-24h-retention"
  resource_group_name                                  = azurerm_resource_group.secondary.name
  recovery_vault_name                                  = azurerm_recovery_services_vault.dr.name
  recovery_point_retention_in_minutes                  = 24 * 60 # keep 24h of recovery points
  application_consistent_snapshot_frequency_in_minutes = 4 * 60  # app-consistent every 4h
}

# ---------- Mappings ----------

resource "azurerm_site_recovery_protection_container_mapping" "primary_to_secondary" {
  name                                      = "map-${var.primary_location}-to-${var.secondary_location}"
  resource_group_name                       = azurerm_resource_group.secondary.name
  recovery_vault_name                       = azurerm_recovery_services_vault.dr.name
  recovery_fabric_name                      = azurerm_site_recovery_fabric.primary.name
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.primary.name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.secondary.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.policy.id
}

resource "azurerm_site_recovery_network_mapping" "primary_to_recovery" {
  name                        = "netmap-primary-to-recovery"
  resource_group_name         = azurerm_resource_group.secondary.name
  recovery_vault_name         = azurerm_recovery_services_vault.dr.name
  source_recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
  target_recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name
  source_network_id           = azurerm_virtual_network.primary.id
  target_network_id           = azurerm_virtual_network.recovery.id
}

# ---------- Cache storage (source region) ----------

resource "random_string" "cache" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "cache" {
  name                            = "stdrcache${random_string.cache.result}"
  location                        = azurerm_resource_group.primary.location
  resource_group_name             = azurerm_resource_group.primary.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = var.tags
}

# ---------- The protected VM ----------

resource "azurerm_site_recovery_replicated_vm" "app01" {
  name                                      = "vm-dr-app01-replica"
  resource_group_name                       = azurerm_resource_group.secondary.name
  recovery_vault_name                       = azurerm_recovery_services_vault.dr.name
  source_recovery_fabric_name               = azurerm_site_recovery_fabric.primary.name
  source_vm_id                              = azurerm_linux_virtual_machine.vm.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.policy.id
  source_recovery_protection_container_name = azurerm_site_recovery_protection_container.primary.name

  target_resource_group_id                = azurerm_resource_group.secondary.id
  target_recovery_fabric_id               = azurerm_site_recovery_fabric.secondary.id
  target_recovery_protection_container_id = azurerm_site_recovery_protection_container.secondary.id
  target_network_id                       = azurerm_virtual_network.recovery.id
  test_network_id                         = azurerm_virtual_network.test.id

  managed_disk {
    disk_id                    = azurerm_linux_virtual_machine.vm.os_disk[0].id
    staging_storage_account_id = azurerm_storage_account.cache.id
    target_resource_group_id   = azurerm_resource_group.secondary.id
    target_disk_type           = "Standard_LRS"
    target_replica_disk_type   = "Standard_LRS"
  }

  network_interface {
    source_network_interface_id = azurerm_network_interface.vm.id
    target_subnet_name          = azurerm_subnet.recovery.name
    target_static_ip            = "10.21.0.10"
    failover_test_subnet_name   = azurerm_subnet.test.name
    failover_test_static_ip     = "10.22.0.10"
  }

  depends_on = [
    azurerm_site_recovery_protection_container_mapping.primary_to_secondary,
    azurerm_site_recovery_network_mapping.primary_to_recovery,
  ]
}
