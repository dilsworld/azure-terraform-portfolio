terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Remote state in Azure Storage - settings in backend.hcl
  backend "azurerm" {}
}

# Default provider = management subscription (logging, policy, MGs)
provider "azurerm" {
  features {}
  subscription_id = var.management_subscription_id
}

# Connectivity subscription (hub network). In a single-subscription lab,
# set connectivity_subscription_id to the same value as management.
provider "azurerm" {
  alias = "connectivity"
  features {}
  subscription_id = coalesce(var.connectivity_subscription_id, var.management_subscription_id)
}

# Landing zone subscription (spoke networks for workloads).
provider "azurerm" {
  alias = "landingzone"
  features {}
  subscription_id = coalesce(var.landingzone_subscription_id, var.management_subscription_id)
}

data "azurerm_client_config" "current" {}
