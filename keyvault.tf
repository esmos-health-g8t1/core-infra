data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "secrets" {
  name                       = "esmos-kv-${random_string.random.result}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # Safe for dev/staging; enable for production

  # Public access for GitHub-hosted runners
  public_network_access_enabled = true

  # Grant the current Terraform executor full access to manage secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.aca_identity.principal_id

    secret_permissions = [
      "Get", "List"
    ]
  }
}

resource "azurerm_key_vault_secret" "core_resource_group" {
  name         = "core-resource-group"
  value        = azurerm_resource_group.rg.name
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "core_env_name" {
  name         = "core-env-name"
  value        = azurerm_container_app_environment.aca_env.name
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "core_acr_name" {
  name         = "core-acr-name"
  value        = azurerm_container_registry.acr.name
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "core_postgres_name" {
  name         = "core-postgres-name"
  value        = azurerm_postgresql_flexible_server.postgres.name
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "postgres_fqdn" {
  name         = "postgres-fqdn"
  value        = azurerm_postgresql_flexible_server.postgres.fqdn
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "db_admin_user" {
  name         = "db-admin-user"
  value        = var.db_admin_user
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "db_admin_password" {
  name         = "db-admin-password"
  value        = var.db_admin_password
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "aca_default_domain" {
  name         = "aca-default-domain"
  value        = azurerm_container_app_environment.aca_env.default_domain
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "aci_subnet_id" {
  name         = "aci-subnet-id"
  value        = azurerm_subnet.aci_subnet.id
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "key_vault_name" {
  name         = "key-vault-name"
  value        = azurerm_key_vault.secrets.name
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "tf_state_storage_account" {
  name         = "tf-state-storage-account"
  value        = azurerm_storage_account.storage.name
  key_vault_id = azurerm_key_vault.secrets.id
}
