# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  # skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "XnK-rg" {
  name     = "${var.Environment}-${var.DefaultName}-Resources"
  location = var.location
}

# Create a Virtual network
resource "azurerm_virtual_network" "XnK-Vn" {
  resource_group_name = azurerm_resource_group.XnK-rg.name
  name                = "${var.Environment}-${var.DefaultName}-VirtNet"
  location            = var.location
  address_space       = var.network
  tags = {
    Environment = var.Environment
  }
}

# Create a Subnet
resource "azurerm_subnet" "XnK-Sn-1" {
  resource_group_name  = azurerm_resource_group.XnK-rg.name
  name                 = "${var.Environment}-${var.DefaultName}-VirtSubnet-1"
  virtual_network_name = azurerm_virtual_network.XnK-Vn.name
  address_prefixes     = var.subnet-1
}

# Create a Network Security Group
resource "azurerm_network_security_group" "XnK-Sg" {
  resource_group_name = azurerm_resource_group.XnK-rg.name
  name                = "${var.Environment}-${var.DefaultName}-NetSecGrp"
  location            = var.location
  tags = {
    Environment = var.Environment
  }
}

# Create a Network Security Rule
resource "azurerm_network_security_rule" "XnK-Dev-Sr" {
  network_security_group_name = azurerm_network_security_group.XnK-Sg.name
  resource_group_name         = azurerm_resource_group.XnK-rg.name
  name                        = "${var.Environment}-${var.DefaultName}-NetSecRule-Dev"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# Create a Subnet Network Security Group Association
resource "azurerm_subnet_network_security_group_association" "XnK-Dev-Sga" {
  subnet_id                 = azurerm_subnet.XnK-Sn-1.id
  network_security_group_id = azurerm_network_security_group.XnK-Sg.id
}

# Add a public IP Address
resource "azurerm_public_ip" "XnK-PubIP-1" {
  name                = "${var.Environment}-${var.DefaultName}-PubIP-1"
  resource_group_name = azurerm_resource_group.XnK-rg.name
  location            = var.location
  allocation_method   = "Dynamic"
  tags = {
    Environment = var.Environment
  }
}

# Create a Network Interface
resource "azurerm_network_interface" "XnK-Nic-1" {
  name                = "${var.Environment}-${var.DefaultName}-Nic-1"
  resource_group_name = azurerm_resource_group.XnK-rg.name
  location            = var.location

  ip_configuration {
    name                          = "${var.Environment}-${var.DefaultName}-Nic-1-Internal"
    subnet_id                     = azurerm_subnet.XnK-Sn-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.XnK-PubIP-1.id
  }
  tags = {
    Environment = var.Environment
  }
}

resource "azurerm_linux_virtual_machine" "XnK-VML-1" {
  name                  = "${var.Environment}-${var.DefaultName}-VML-1"
  resource_group_name   = azurerm_resource_group.XnK-rg.name
  location              = var.location
  size                  = var.VM-Size-1
  admin_username        = var.AdminUser
  network_interface_ids = [azurerm_network_interface.XnK-Nic-1.id]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = var.AdminUser
    public_key = file("~/.ssh/xnkazurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-script.tpl", {
      host         = "${var.Environment}-${var.DefaultName}-VML-1",
      hostname     = self.public_ip_address,
      user         = var.AdminUser,
      identityfile = "~/.ssh/xnkazurekey",
    })
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }

  tags = {
    Environment = var.Environment
  }
}

data "azurerm_public_ip" "XnK-IP-Data" {
  name                = azurerm_public_ip.XnK-PubIP-1.name
  resource_group_name = azurerm_resource_group.XnK-rg.name
}

output "VM-IP-Address" {
  value = "${azurerm_linux_virtual_machine.XnK-VML-1.name}: ${azurerm_public_ip.XnK-PubIP-1.ip_address}"
}