resource "random_password" "odoo_db_password" {
  length  = 24
  special = false
}

resource "random_password" "moodle_db_password" {
  length  = 24
  special = false
}

resource "random_password" "peppermint_db_password" {
  length  = 24
  special = false
}

resource "azurerm_key_vault_secret" "odoo_db_user" {
  name         = "odoo-db-user"
  value        = "odoo_user"
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "odoo_db_password" {
  name         = "odoo-db-password"
  value        = random_password.odoo_db_password.result
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "moodle_db_user" {
  name         = "moodle-db-user"
  value        = "moodle_user"
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "moodle_db_password" {
  name         = "moodle-db-password"
  value        = random_password.moodle_db_password.result
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "peppermint_db_user" {
  name         = "peppermint-db-user"
  value        = "peppermint_user"
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "peppermint_db_password" {
  name         = "peppermint-db-password"
  value        = random_password.peppermint_db_password.result
  key_vault_id = azurerm_key_vault.secrets.id
}
