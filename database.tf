resource "random_string" "random" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "esmos-postgres-dns.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_vnet_link" {
  name                  = "postgres-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "esmos-postgres-${random_string.random.result}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "15"
  delegated_subnet_id    = azurerm_subnet.postgres_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres_dns.id
  zone                   = "1"
  administrator_login    = var.db_admin_user
  administrator_password = var.db_admin_password

  sku_name   = "B_Standard_B1ms" # Cost-effective burstable tier
  storage_mb = 32768             # 32GB

  public_network_access_enabled = false

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres_vnet_link]
}

resource "azurerm_postgresql_flexible_server_database" "odoo_db" {
  name      = "odoo"
  server_id = azurerm_postgresql_flexible_server.postgres.id
}

resource "azurerm_postgresql_flexible_server_database" "moodle_db" {
  name      = "moodle"
  server_id = azurerm_postgresql_flexible_server.postgres.id
}

resource "azurerm_postgresql_flexible_server_database" "peppermint_db" {
  name      = "peppermint"
  server_id = azurerm_postgresql_flexible_server.postgres.id
}
