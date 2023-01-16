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