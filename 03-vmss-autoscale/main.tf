terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}

# Subscription comes from ARM_SUBSCRIPTION_ID
provider "azurerm" {
  features {}
}

# Your public IP in CIDR form, e.g. 1.2.3.4/32 (set in terraform.tfvars)
variable "my_ip" {
  type = string
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

# RESOURCE GROUP
resource "azurerm_resource_group" "scaleset" {
  name     = "udemytestscaleset"
  location = "UK South"
}

# VNET
resource "azurerm_virtual_network" "scale_vnet" {
  name                = "udemytestscalesetvnet"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.scaleset.name
  location            = azurerm_resource_group.scaleset.location
}

# SUBNET
resource "azurerm_subnet" "scale_subnet" {
  name                 = "udemytestscalesetsubnet"
  resource_group_name  = azurerm_resource_group.scaleset.name
  virtual_network_name = azurerm_virtual_network.scale_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# NSG - SSH from your IP only
resource "azurerm_network_security_group" "ssh" {
  name                = "udemytestscalesetnsg"
  resource_group_name = azurerm_resource_group.scaleset.name
  location            = azurerm_resource_group.scaleset.location

  security_rule {
    name                       = "allow-ssh-from-me"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }
}

# SCALE SET
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "azureudemyscaleset"
  resource_group_name = azurerm_resource_group.scaleset.name
  location            = azurerm_resource_group.scaleset.location
  sku                 = "Standard_D2nls_v6" # 2 vCPU, low memory - cheap lab size
  instances           = 1
  zones               = ["1", "2", "3"] # if a zone error appears, use ["1"] or remove this line
  upgrade_mode        = "Automatic"

  computer_name_prefix = "udemy-scaleset"
  admin_username       = "udemyadministrator"

  # SSH key only - password login disabled
  disable_password_authentication = true

  admin_ssh_key {
    username   = "udemyadministrator"
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name                      = "scaleprofile"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.ssh.id

    ip_configuration {
      name      = "vmss"
      primary   = true
      subnet_id = azurerm_subnet.scale_subnet.id

      # Each instance gets its own public IP
      public_ip_address {
        name = "vmss-pip"
      }
    }
  }
}

# AUTOSCALE SETTINGS
resource "azurerm_monitor_autoscale_setting" "scale_setting" {
  name                = "scalesettingudemy"
  resource_group_name = azurerm_resource_group.scaleset.name
  location            = azurerm_resource_group.scaleset.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 90
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 10
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}

output "list_instance_ips" {
  value = "az vmss list-instance-public-ips -g ${azurerm_resource_group.scaleset.name} -n ${azurerm_linux_virtual_machine_scale_set.vmss.name} --query '[].ipAddress' -o tsv"
}