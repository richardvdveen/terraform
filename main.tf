# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

# Configure Azure as the provider used for this deployment
provider "azurerm" {
  features {}
}

# A resource group to logically group the infra elements in the Azure subscription
resource "azurerm_resource_group" "rg" {
  name     = "infrastructure"
  location = var.location
}

resource "azurerm_network_security_group" "infra" {
  name                = "infra"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow_ssh"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    access                     = "Allow"
    priority                   = 150
    direction                  = "Inbound"
  }

  security_rule {
    name                       = "allow_http"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "Internet"
    destination_port_range     = 80
    destination_address_prefix = "*"
    access                     = "Allow"
    priority                   = 151
    direction                  = "Inbound"
  }

  security_rule {
    name                       = "allow_https"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 443
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    access                     = "Allow"
    priority                   = 152
    direction                  = "Inbound"
  }

  security_rule {
    name                       = "allow_udp"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = 34197
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    access                     = "Allow"
    priority                   = 153
    direction                  = "Inbound"
  }
}

# A Virtual Network for the Servers and Workers to reside in
resource "azurerm_virtual_network" "infra" {
  name                = "infra"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
}

# An initial subnet for personal deployed resources
resource "azurerm_subnet" "personal" {
  name                 = "personal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.infra.name
  address_prefixes     = ["10.0.1.0/24"]
}

# A public IP for the Control node
resource "azurerm_public_ip" "control" {
  name                = "control"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  allocation_method   = "Dynamic"
}

# A Network Interface for the control node
resource "azurerm_network_interface" "control" {
  name                    = "control"
  resource_group_name     = azurerm_resource_group.rg.name
  internal_dns_name_label = "control"
  ip_configuration {
    name                          = "control"
    subnet_id                     = azurerm_subnet.personal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.control.id
  }
  location = var.location
}

# A Network Interface for the worker1 node
resource "azurerm_network_interface" "worker1" {
  name                    = "worker1"
  resource_group_name     = azurerm_resource_group.rg.name
  internal_dns_name_label = "worker1"
  ip_configuration {
    name                          = "worker1"
    subnet_id                     = azurerm_subnet.personal.id
    private_ip_address_allocation = "Dynamic"
  }
  location = var.location
}

# A Network Interface for the server1 node
resource "azurerm_network_interface" "server1" {
  name                    = "server1"
  resource_group_name     = azurerm_resource_group.rg.name
  internal_dns_name_label = "server1"
  ip_configuration {
    name                          = "server1"
    subnet_id                     = azurerm_subnet.personal.id
    private_ip_address_allocation = "Dynamic"
  }
  location = var.location
}

# A Network Interface for the server2 node
resource "azurerm_network_interface" "server2" {
  name                    = "server2"
  resource_group_name     = azurerm_resource_group.rg.name
  internal_dns_name_label = "server2"
  ip_configuration {
    name                          = "server2"
    subnet_id                     = azurerm_subnet.personal.id
    private_ip_address_allocation = "Dynamic"
  }
  location = var.location
}

resource "azurerm_linux_virtual_machine" "control" {
  admin_username        = "richard"
  location              = var.location
  name                  = "control"
  network_interface_ids = [azurerm_network_interface.control.id]
  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"
  admin_ssh_key {
    username   = "richard"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC0NubwKiNFVi29hwDHo9IAVFosMsbQg5G34Yo/8dQC9jy7fB//SpDxgVoygVcvcfPptVoEByTFRnpuOadBUO5u2L3d3wlyrfT3hoEtW5adSw738MnW3e/RHkjHp/LjsIox4CYPJy8Dw4D4j/EF4L5946dXN3gfkNF4tnlsA/jSxXRn+dB/cZILwElqiU4SyG9BLXT9M13E+rP+J/1K+yCdc+Pgyq8XA/7Zwb4vf/LE0sftDpcMjzEdNF3yem0hQENp0kGNhqkfX5ic9V4dkbCkPySP3jqSwdhYizn377KcZleCrcwGWAhxJPL6lyrmCgUWB1vyxzVg8sftTYNHt2Z2s347BJHRenPTWoCi3Adc8K31+TGON7sLLYfpjCGtn1AhUN+bp6n5/qipw+/Yemb0Sg7HugLcGlmcaBn29gyw2edHlz040XbTzJCWQlV8SMR2yRV7Fh30FVokBeCLRGMb2uYQDoD65GmYiPAGPdGGGZvdAuQccj/I0iL0026qI/U= richard@LAPTOP-FE9DSLNQ"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "server1" {
  admin_username        = "richard"
  location              = var.location
  name                  = "server1"
  network_interface_ids = [azurerm_network_interface.server1.id]
  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1ms"
  admin_ssh_key {
    username   = "richard"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/Oz4PrsD3MiWHYbQvtE1ZF2yCuYgDegQnyxI5kjyWgE1IqkODEekgMSe9gvRIusegsr2FOmotJxWotR8TeiTvPtj7f/p52CtDb4pd3j+0hpLNezO2MH61WmgYHUm7Z4AGGxupuHRKCGD7bjqRFGTYrFR3JedtukBfKwCjeUkvJnMK5HTVredI5CUGBEfuhWWwBQcI9GFUiwmKUmNo8mVtJIIAotwPpXfIWG0HZRug5tg9DnB6xdDWXsngTjuLUpeaMEOanKMOK14GjS0mnEmg6X3/aCktw4R213Ddugtglfv7OaH98f/ML4OEe7+DakPLZrD4erBw0r5qtPzrzBWEfwglqHowPfAuFVR5abLXzrrA1QJqOndx72QhgTQ2YCp2q7f0gB30ltIH3pXQkl2rI7z+1Qnto/OiguMCjG5hOfAGvkuZq64Cz2pMqhv15Tna5uRkohrLpg1YsnrBLLsUut/KF4vH6TefsSXLLEtJhDxRUfZXMfvM71GZ0Xnlq18= richard@control"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "server2" {
  admin_username        = "richard"
  location              = var.location
  name                  = "server2"
  network_interface_ids = [azurerm_network_interface.server2.id]
  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1ms"
  admin_ssh_key {
    username   = "richard"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/Oz4PrsD3MiWHYbQvtE1ZF2yCuYgDegQnyxI5kjyWgE1IqkODEekgMSe9gvRIusegsr2FOmotJxWotR8TeiTvPtj7f/p52CtDb4pd3j+0hpLNezO2MH61WmgYHUm7Z4AGGxupuHRKCGD7bjqRFGTYrFR3JedtukBfKwCjeUkvJnMK5HTVredI5CUGBEfuhWWwBQcI9GFUiwmKUmNo8mVtJIIAotwPpXfIWG0HZRug5tg9DnB6xdDWXsngTjuLUpeaMEOanKMOK14GjS0mnEmg6X3/aCktw4R213Ddugtglfv7OaH98f/ML4OEe7+DakPLZrD4erBw0r5qtPzrzBWEfwglqHowPfAuFVR5abLXzrrA1QJqOndx72QhgTQ2YCp2q7f0gB30ltIH3pXQkl2rI7z+1Qnto/OiguMCjG5hOfAGvkuZq64Cz2pMqhv15Tna5uRkohrLpg1YsnrBLLsUut/KF4vH6TefsSXLLEtJhDxRUfZXMfvM71GZ0Xnlq18= richard@control"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "worker1" {
  admin_username        = "richard"
  location              = var.location
  name                  = "worker1"
  network_interface_ids = [azurerm_network_interface.worker1.id]
  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"
  admin_ssh_key {
    username   = "richard"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/Oz4PrsD3MiWHYbQvtE1ZF2yCuYgDegQnyxI5kjyWgE1IqkODEekgMSe9gvRIusegsr2FOmotJxWotR8TeiTvPtj7f/p52CtDb4pd3j+0hpLNezO2MH61WmgYHUm7Z4AGGxupuHRKCGD7bjqRFGTYrFR3JedtukBfKwCjeUkvJnMK5HTVredI5CUGBEfuhWWwBQcI9GFUiwmKUmNo8mVtJIIAotwPpXfIWG0HZRug5tg9DnB6xdDWXsngTjuLUpeaMEOanKMOK14GjS0mnEmg6X3/aCktw4R213Ddugtglfv7OaH98f/ML4OEe7+DakPLZrD4erBw0r5qtPzrzBWEfwglqHowPfAuFVR5abLXzrrA1QJqOndx72QhgTQ2YCp2q7f0gB30ltIH3pXQkl2rI7z+1Qnto/OiguMCjG5hOfAGvkuZq64Cz2pMqhv15Tna5uRkohrLpg1YsnrBLLsUut/KF4vH6TefsSXLLEtJhDxRUfZXMfvM71GZ0Xnlq18= richard@control"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}