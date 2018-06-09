provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  tenant_id       = "${var.tenant_id}"
}

resource "azurerm_resource_group" "multipleStorageAccRG" {
  name     = "multipleStorageRG"
  location = "${var.location}"
  tags     = { "env" = "POC" } 
}

resource "azurerm_storage_account" "multipleStorageAcc" {
  resource_group_name      = "multipleStorageRG"
  tags                     = { "CreatedBy" = "Terraform"} 
  location                 = "${var.location}"
  account_tier             = "standard"
  account_replication_type = "LRS"
  count                    = 10
  name                     = "terraformstrg${count.index}"
  
  # storage account depends on resource group
  depends_on = ["azurerm_resource_group.multipleStorageAccRG"]
}
