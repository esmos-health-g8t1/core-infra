resource "azurerm_storage_account" "storage" {
  name                     = "esmosstorage${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Local redundancy for cost optimization
}

resource "azurerm_storage_share" "odoo_data" {
  name                 = "odoo-data"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 50
}

resource "azurerm_storage_share" "moodle_data" {
  name                 = "moodle-data"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 50
}

resource "azurerm_storage_share" "peppermint_data" {
  name                 = "peppermint-data"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 50
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
