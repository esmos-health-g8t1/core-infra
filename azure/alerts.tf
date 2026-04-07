# ── Container App data sources (deployed by separate Terraform roots) ─────────
# TODO: uncomment once odoo-app and moodle-app are deployed
data "azurerm_container_app" "odoo" {
  name                = "odoo-app"
  resource_group_name = azurerm_resource_group.rg.name
}

data "azurerm_container_app" "moodle" {
  name                = "moodle-app"
  resource_group_name = azurerm_resource_group.rg.name
}

# ── Action Group ──────────────────────────────────────────────────────────────
resource "azurerm_monitor_action_group" "slack" {
  name                = "esmos-slack-alerts"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "esmos-slack"

  # Slack email integration — Azure Monitor emails this address and Slack
  # posts it to the bound channel automatically. No webhook JSON formatting needed.
  email_receiver {
    name          = "slack-channel"
    email_address = "azure-monitor-aaaatvqw3nh4cslm4tb37hvksy@esmos-g8t1.slack.com"
  }
}

# ── PostgreSQL alerts ─────────────────────────────────────────────────────────

resource "azurerm_monitor_metric_alert" "postgres_cpu" {
  name                = "postgres-cpu-high"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_postgresql_flexible_server.postgres.id]
  description         = "Postgres CPU > 80% for 5 min — DB under heavy load"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.slack.id
  }
}

resource "azurerm_monitor_metric_alert" "postgres_memory" {
  name                = "postgres-memory-high"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_postgresql_flexible_server.postgres.id]
  description         = "Postgres memory > 85% — risk of OOM kills and query spills to disk"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "memory_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.slack.id
  }
}

resource "azurerm_monitor_metric_alert" "postgres_storage" {
  name                = "postgres-storage-high"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_postgresql_flexible_server.postgres.id]
  description         = "Postgres storage > 80% — provision more storage before it hits 100%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.slack.id
  }
}

resource "azurerm_monitor_metric_alert" "postgres_connections_failed" {
  name                = "postgres-connections-failed"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_postgresql_flexible_server.postgres.id]
  description         = "Postgres connection failures > 10 in 5 min — likely hitting max_connections or auth errors"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "connections_failed"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.slack.id
  }
}

resource "azurerm_monitor_metric_alert" "postgres_deadlocks" {
  name                = "postgres-deadlocks"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_postgresql_flexible_server.postgres.id]
  description         = "Postgres deadlocks detected — Odoo or Moodle have contention issues"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "deadlocks"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.slack.id
  }
}

# PgBouncer-specific: fires when client connections are queueing up,
# meaning all pool slots are busy. Useful signal during load testing.
resource "azurerm_monitor_metric_alert" "pgbouncer_waiting" {
  name                = "pgbouncer-clients-waiting"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_postgresql_flexible_server.postgres.id]
  description         = "PgBouncer has > 20 clients waiting for a pool slot — increase default_pool_size or scale the DB"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "client_connections_waiting"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 20
  }

  action {
    action_group_id = azurerm_monitor_action_group.slack.id
  }
}

# ── Container App alerts (Odoo + Moodle — heavy apps) ────────────────────────

resource "azurerm_monitor_metric_alert" "odoo_replicas_maxed" {
  name                = "odoo-replicas-at-max"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [data.azurerm_container_app.odoo.id]
  description         = "Odoo is at max replica count — scaling ceiling hit, requests may be queuing"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "Replicas"
    aggregation      = "Maximum"
    operator         = "GreaterThanOrEqual"
    threshold        = 10 # update this to match max_replicas when you set scaling rules
  }

  action {
    action_group_id = azurerm_monitor_action_group.slack.id
  }
}

resource "azurerm_monitor_metric_alert" "moodle_replicas_maxed" {
  name                = "moodle-replicas-at-max"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [data.azurerm_container_app.moodle.id]
  description         = "Moodle is at max replica count — scaling ceiling hit"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "Replicas"
    aggregation      = "Maximum"
    operator         = "GreaterThanOrEqual"
    threshold        = 10 # update to match max_replicas
  }

  action {
    action_group_id = azurerm_monitor_action_group.slack.id
  }
}

resource "azurerm_monitor_metric_alert" "odoo_restarts" {
  name                = "odoo-container-restarts"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [data.azurerm_container_app.odoo.id]
  description         = "Odoo container restart detected — crash loop or OOM kill"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "RestartCount"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.slack.id
  }
}

resource "azurerm_monitor_metric_alert" "moodle_restarts" {
  name                = "moodle-container-restarts"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [data.azurerm_container_app.moodle.id]
  description         = "Moodle container restart detected — crash loop or OOM kill"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "RestartCount"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.slack.id
  }
}

resource "azurerm_monitor_metric_alert" "odoo_response_time" {
  name                = "odoo-response-time-high"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [data.azurerm_container_app.odoo.id]
  description         = "Odoo p95 response time > 5s — likely DB bottleneck or under-scaled"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "ResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5000 # milliseconds
  }

  action {
    action_group_id = azurerm_monitor_action_group.slack.id
  }
}

