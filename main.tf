provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "infrasrv" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "infrasrv" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.infrasrv.location
  resource_group_name = azurerm_resource_group.infrasrv.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.infrasrv.name
  virtual_network_name = azurerm_virtual_network.infrasrv.name
  address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.infrasrv.name
  location            = azurerm_resource_group.infrasrv.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "infrasrv" {
  name                = "${var.prefix}-nic1"
  resource_group_name = azurerm_resource_group.infrasrv.name
  location            = azurerm_resource_group.infrasrv.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface" "internal" {
  name                      = "${var.prefix}-nic2"
  resource_group_name       = azurerm_resource_group.infrasrv.name
  location                  = azurerm_resource_group.infrasrv.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "webserver" {
  name                = "tls_webserver"
  location            = azurerm_resource_group.infrasrv.location
  resource_group_name = azurerm_resource_group.infrasrv.name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "tls"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "443"
    destination_address_prefix = azurerm_network_interface.infrasrv.private_ip_address
  }
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface_security_group_association" "infrasrv" {
  network_interface_id      = azurerm_network_interface.internal.id
  network_security_group_id = azurerm_network_security_group.webserver.id
}

resource "azurerm_linux_virtual_machine" "infrasrv" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.infrasrv.name
  location                        = azurerm_resource_group.infrasrv.location
  size                            = "Standard_F2"
  admin_username                  = "sampleAdminHideIt"
  admin_password                  = "sampleP@ssHideIt!!!"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.infrasrv.id,
    azurerm_network_interface.internal.id,
  ]

  admin_ssh_key {
    username = "sampleAdminHideIt"
    public_key = file("~/.ssh/azure_vm_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

}
