provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  tenant_id       = "${var.tenant_id}"
}

# Resource Group
resource "azurerm_resource_group" "SingleVM" {
  name     = "singleVMRG"
  location = "${var.location}"
  tags     = { "env" = "DEV", "createdBy" = "Terraform" } 
}

# Virutal Network
resource "azurerm_virtual_network" "SingleVM" {
  name                = "singleVMVNET"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.SingleVM.name}"
  depends_on          = ["azurerm_resource_group.SingleVM"] 
}

# VM subnet
resource "azurerm_subnet" "SingleVM" {
  name                 = "vmsubnet"
  resource_group_name  = "${azurerm_resource_group.SingleVM.name}"
  virtual_network_name = "${azurerm_virtual_network.SingleVM.name}"
  address_prefix       = "10.0.2.0/24"
  network_security_group_id = "${azurerm_network_security_group.SingleVM.id}"
}

resource "azurerm_public_ip" "SingleVM" {
  name                         = "singlevmPublicIp1"
  location                     = "${azurerm_resource_group.SingleVM.location}"
  resource_group_name          = "${azurerm_resource_group.SingleVM.name}"
  public_ip_address_allocation = "dynamic"
}

# VM Network Interface Card
resource "azurerm_network_interface" "SingleVM" {
  name                = "testvmnic"
  location            = "${azurerm_resource_group.SingleVM.location}"
  resource_group_name = "${azurerm_resource_group.SingleVM.name}"

  ip_configuration {
    name                          = "SingleVMconfiguration1"
    subnet_id                     = "${azurerm_subnet.SingleVM.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.SingleVM.id}"
  }
}

# Manage DIsk resource
resource "azurerm_managed_disk" "SingleVM" {
  name                 = "datadisk"
  location             = "${azurerm_resource_group.SingleVM.location}"
  resource_group_name  = "${azurerm_resource_group.SingleVM.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

# Network Security Group
resource "azurerm_network_security_group" "SingleVM" {
  name                = "singleVMNSG"
  location            = "${azurerm_resource_group.SingleVM.location}"
  resource_group_name = "${azurerm_resource_group.SingleVM.name}"
}

# Network Security Rules
resource "azurerm_network_security_rule" "ssh_access" {
  name                          = "ssh-access-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "22"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.SingleVM.name}"
  network_security_group_name = "${azurerm_network_security_group.SingleVM.name}"
}

resource "azurerm_virtual_machine" "SingleVM" {
  name                  = "ubuntuvm"
  location              = "${azurerm_resource_group.SingleVM.location}"
  resource_group_name   = "${azurerm_resource_group.SingleVM.name}"
  network_interface_ids = ["${azurerm_network_interface.SingleVM.id}"]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  # data disk
  storage_data_disk {
    name            = "${azurerm_managed_disk.SingleVM.name}"
    managed_disk_id = "${azurerm_managed_disk.SingleVM.id}"
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = "${azurerm_managed_disk.SingleVM.disk_size_gb}"
  }

  os_profile {
    computer_name  = "singlevm"
    admin_username = "vmadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "development"
  }
}
