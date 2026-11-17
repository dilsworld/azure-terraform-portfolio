# providers.tf
terraform {
  required_version = ">= 1.6"

  # Remote state in Azure Storage - settings in backend.hcl (written by ../bootstrap)
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
