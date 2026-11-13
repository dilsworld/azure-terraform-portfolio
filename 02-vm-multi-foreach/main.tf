# =============================================================================
# first_vm/main.tf
# Ubuntu VMs in UK South, generated from per-environment counts in
# local.environments. Each VM gets its own public IP, NIC and NSG
# (SSH from var.my_ip only, key-based login).
#
# Quota note: subscription limit is 10 vCPUs in UK South.
# Standard_D2ns_v6 = 2 vCPUs, so max 5 VMs in total.
# =============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.10"
    }
  }
}

provider "azurerm" {
  features {}
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
variable "prefix" {
  description = "Prefix for the shared resource group and VNet"
  default     = "lab"
}

variable "location" {
  description = "Azure region"
  default     = "uksouth"
}

variable "my_ip" {
  description = "Your home public IP in CIDR form, e.g. 1.2.3.4/32"
  type        = string
}

variable "admin_username" {
  description = "Admin user created on the VMs"
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used to log in"
  default     = "~/.ssh/azure_lab.pub"
}

# -----------------------------------------------------------------------------
# Server list.
# Set how many VMs you want per environment in local.environments.
# local.vms expands that into one entry per VM, e.g.:
#   "prod-01" = { env = "prod", instance = "01", size = "Standard_D2ns_v6" }
# each.key   = "prod-01"  (unique ID used to link resources together)
# each.value = { env, instance, size }  (used in names, tags and sizing)
# -----------------------------------------------------------------------------
locals {
  environments = {
    prod = 2
    test = 1
    uat  = 2
  }

  vm_size = "Standard_D2ns_v6"

  vms = merge([
    for env, n in local.environments : {
      for i in range(1, n + 1) :
      "${env}-${format("%02d", i)}" => {
        env      = env
        instance = format("%02d", i)
        size     = local.vm_size
      }
    }
  ]...)
}

# -----------------------------------------------------------------------------
# Shared: resource group and networking (one of each)
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# -----------------------------------------------------------------------------
# Per-VM resources: one of each per entry in local.vms.
# Names use each.value.env / each.value.instance (e.g. vm-app-prod-uks-01).
# Links between resources use [each.key] (e.g. "prod-01").
# -----------------------------------------------------------------------------
resource "azurerm_public_ip" "vm" {
  for_each = local.vms

  name                = "pip-app-${each.value.env}-uks-${each.value.instance}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = each.value.env
  }
}

resource "azurerm_network_interface" "vm" {
  for_each = local.vms

  name                = "nic-app-${each.value.env}-uks-${each.value.instance}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm[each.key].id
  }

  tags = {
    environment = each.value.env
  }
}

resource "azurerm_network_security_group" "vm" {
  for_each = local.vms

  name                = "nsg-app-${each.value.env}-uks-${each.value.instance}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-SSH-MyIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }

  tags = {
    environment = each.value.env
  }
}

resource "azurerm_network_interface_security_group_association" "vm" {
  for_each = local.vms

  network_interface_id      = azurerm_network_interface.vm[each.key].id
  network_security_group_id = azurerm_network_security_group.vm[each.key].id
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = local.vms

  name                  = "vm-app-${each.value.env}-uks-${each.value.instance}"
  computer_name         = "vm-app-${each.value.env}-uks-${each.value.instance}"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  size                  = each.value.size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.vm[each.key].id]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    name                 = "osdisk-app-${each.value.env}-uks-${each.value.instance}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    environment = each.value.env
  }
}

# -----------------------------------------------------------------------------
# Output: an SSH command per VM, keyed by e.g. "prod-01"
# -----------------------------------------------------------------------------
output "ssh_commands" {
  value = {
    for k, pip in azurerm_public_ip.vm :
    k => "ssh -i ~/.ssh/azure_lab ${var.admin_username}@${pip.ip_address}"
  }
}