# The "production" server. No public IP - check it via Boot diagnostics /
# Serial console in the portal, or reach it through Bastion if you peer it.

resource "azurerm_network_interface" "vm" {
  name                = "nic-dr-app01"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.primary.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.0.10"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "vm-dr-app01"
  resource_group_name   = azurerm_resource_group.primary.name
  location              = azurerm_resource_group.primary.location
  size                  = var.vm_size
  admin_username        = "azureadmin"
  network_interface_ids = [azurerm_network_interface.vm.id]
  tags                  = var.tags

  admin_ssh_key {
    username   = "azureadmin"
    public_key = var.ssh_public_key != null && var.ssh_public_key != "" ? trimspace(var.ssh_public_key) : file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    name                 = "osdisk-dr-app01"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Managed boot diagnostics = screenshot + serial console after failover
  boot_diagnostics {}

  # A web page that shows which region the server is running in, so you can
  # prove a failover worked (curl from the serial console).
  custom_data = base64encode(<<-EOF
    #cloud-config
    package_update: true
    packages:
      - nginx
      - jq
    write_files:
      - path: /usr/local/bin/whereami.sh
        permissions: "0755"
        content: |
          #!/bin/bash
          REGION=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute/location?api-version=2021-02-01&format=text")
          echo "<h1>vm-dr-app01 is running in: $REGION</h1><p>$(date)</p>" > /var/www/html/index.html
      - path: /etc/cron.d/whereami
        content: |
          * * * * * root /usr/local/bin/whereami.sh
    runcmd:
      - /usr/local/bin/whereami.sh
      - systemctl enable --now nginx
  EOF
  )
}
