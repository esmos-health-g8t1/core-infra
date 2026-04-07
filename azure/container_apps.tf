resource "azurerm_user_assigned_identity" "aca_identity" {
  name                = "aca-identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "esmos-logs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "aca_env" {
  name                       = "esmos-env"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  infrastructure_subnet_id   = azurerm_subnet.aca_subnet.id

  # Using consumption tier
  lifecycle {
    ignore_changes = [
      infrastructure_resource_group_name,
    ]
  }
}

resource "azurerm_container_registry" "acr" {
  name                = "esmosregistry${random_string.random.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

# Container App Environment Storage Links (Azure Files)
resource "azurerm_container_app_environment_storage" "odoo_storage" {
  name                         = "odoo-storage"
  container_app_environment_id = azurerm_container_app_environment.aca_env.id
  account_name                 = azurerm_storage_account.storage.name
  access_key                   = azurerm_storage_account.storage.primary_access_key
  share_name                   = azurerm_storage_share.odoo_data.name
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "moodle_storage" {
  name                         = "moodle-storage"
  container_app_environment_id = azurerm_container_app_environment.aca_env.id
  account_name                 = azurerm_storage_account.storage.name
  access_key                   = azurerm_storage_account.storage.primary_access_key
  share_name                   = azurerm_storage_share.moodle_data.name
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "peppermint_storage" {
  name                         = "peppermint-storage"
  container_app_environment_id = azurerm_container_app_environment.aca_env.id
  account_name                 = azurerm_storage_account.storage.name
  access_key                   = azurerm_storage_account.storage.primary_access_key
  share_name                   = azurerm_storage_share.peppermint_data.name
  access_mode                  = "ReadWrite"
}
resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

resource "azurerm_role_assignment" "rg_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}
