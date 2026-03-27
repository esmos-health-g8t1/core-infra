output "resource_group_name" {
  description = "The name of the Resource Group created"
  value       = azurerm_resource_group.rg.name
}

output "acr_login_server" {
  description = "The login server for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "postgres_fqdn" {
  description = "The FQDN of the PostgreSQL database server"
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "key_vault_name" {
  description = "The name of the Azure Key Vault storing infrastructure secrets"
  value       = azurerm_key_vault.secrets.name
}
