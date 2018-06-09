provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  tenant_id       = "${var.tenant_id}"
}

resource "azurerm_resource_group" "terrformpocRG" {
  name     = "terrformpocRG"
  location = "${var.location}"
  tags     = { "env" = "POC" } 
}
