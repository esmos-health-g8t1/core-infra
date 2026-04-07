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

  sku_name   = "GP_Standard_D2s_v3" # General purpose: 2 vCores, 8GB RAM, ~250 max_connections
  storage_mb = 32768                # 32GB

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

resource "azurerm_postgresql_flexible_server_database" "bridge_db" {
  name      = "bridge"
  server_id = azurerm_postgresql_flexible_server.postgres.id
}

# ── Built-in PgBouncer connection pooler ──────────────────────────────────────
# Apps connect to port 6432 (PgBouncer) instead of 5432 (Postgres directly).
# PgBouncer multiplexes replica connections into a fixed server-side pool,
# preventing "too many clients" during load testing and auto-scaling events.
#
# session mode: required for Odoo (uses advisory locks + SET commands).
# default_pool_size = 40 per db/user pair → max 120 real Postgres connections
#   across 3 apps, well within the ~250 limit of GP_D2s_v3.
# max_client_conn = 1000: how many app-side connections PgBouncer will accept
#   before queuing — gives headroom for aggressive load test replica counts.
resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_enabled" {
  name      = "pgbouncer.enabled"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "True"
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_pool_mode" {
  name      = "pgbouncer.pool_mode"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "session"
  depends_on = [azurerm_postgresql_flexible_server_configuration.pgbouncer_enabled]
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_default_pool_size" {
  name      = "pgbouncer.default_pool_size"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "40"
  depends_on = [azurerm_postgresql_flexible_server_configuration.pgbouncer_enabled]
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_max_client_conn" {
  name      = "pgbouncer.max_client_conn"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "1000"
  depends_on = [azurerm_postgresql_flexible_server_configuration.pgbouncer_enabled]
}
