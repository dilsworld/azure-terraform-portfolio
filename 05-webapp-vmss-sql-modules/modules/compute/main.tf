resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss-${var.project_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.vm_size
  instances           = var.vmss_instance_count
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = var.web_subnet_id
      load_balancer_backend_address_pool_ids = [var.backend_pool_id]
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

output "vmss_principal_id" {
  value = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].principal_id
}