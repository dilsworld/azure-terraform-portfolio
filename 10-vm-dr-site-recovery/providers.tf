terraform {
  required_version = ">= 1.6"

  # Remote state in Azure Storage - settings in backend.hcl
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    # Site Recovery drops replica disks and test-failover leftovers into the
    # secondary resource group. Let destroy remove them rather than fail.
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    # Lab only: don't leave a soft-deleted vault behind after destroy.
    recovery_service {
      vm_backup_stop_protection_and_retain_data_on_destroy = false
      purge_protected_items_from_vault_on_destroy          = true
    }
  }
}
