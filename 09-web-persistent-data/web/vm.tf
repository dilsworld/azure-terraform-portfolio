# vm.tf
resource "azurerm_network_interface" "web" {
  name                = "nic-${var.prefix}-web"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = data.azurerm_public_ip.web.id # static IP from persistent layer
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  name                  = "vm-${var.prefix}-web"
  location              = azurerm_resource_group.web.location
  resource_group_name   = azurerm_resource_group.web.name
  size                  = var.vm_size
  disk_controller_type  = "NVMe"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.web.id]

  # Builds the server the same way every time: mount data disk, install nginx
  custom_data = base64encode(templatefile("${path.module}/cloud-init.sh.tftpl", {
    disk_size_gb = data.azurerm_managed_disk.webdata.disk_size_gb
  }))

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key != null && var.ssh_public_key != "" ? trimspace(var.ssh_public_key) : file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

# Attach the persistent data disk to whichever VM is current
resource "azurerm_virtual_machine_data_disk_attachment" "webdata" {
  managed_disk_id    = data.azurerm_managed_disk.webdata.id
  virtual_machine_id = azurerm_linux_virtual_machine.web.id
  lun                = 0
  caching            = "ReadWrite"
}
