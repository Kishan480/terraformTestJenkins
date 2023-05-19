terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.55.0"
    }
  }
}


provider "azurerm" {
  features {}
  subscription_id = "84ce48b2-19e4-4d7c-96a2-2e3508692c89"
  client_id       = "764aed4d-5c9e-4cfe-99e5-7ac70d4ea972"
  client_secret   = "NAO8Q~8mNAgX9kpC3qjs-eJ5LfpD-tTMM3JfnbpU"
  tenant_id       = "815db2f7-1e3a-438f-8bdd-e55de825adee"	
}


resource "azurerm_resource_group" "rg" {
  name     = "my-resource-group"
  location = "eastus"
}

# Define the virtual network and subnet
resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "subnet" {
  name                 = "my-subnet"
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
}

# Define the public IP address
resource "azurerm_public_ip" "publicip" {
  name                = "my-public-ip"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"

}

# Define the network security group
resource "azurerm_network_security_group" "nsg" {
  name                = "my-nsg"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "Allow-RDP-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Define the network interface
resource "azurerm_network_interface" "nic" {
  name                = "my-nic"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "my-ip-config"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_network_security_group.nsg]
}

# Define the virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "my-vm"
  location              = "${azurerm_resource_group.rg.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.nic.id}"]
  vm_size               = "Standard_D2s_v3"

  storage_os_disk {
    name              = "my-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    # version   = "18.09.0-1004"
    version ="latest"
  }
  os_profile_windows_config {
    provision_vm_agent = true
    } 


  os_profile {
    computer_name  = "my-vm"
    admin_username = "adminuser"
    admin_password = "King@9721"
  }
   
}
