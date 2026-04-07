# Azure Policies Assignment for Governance (Delighters)

# 1. Enforce Data Residency (Allowed Locations)
resource "azurerm_resource_group_policy_assignment" "allowed_locations" {
  name                 = "deny-non-sea-hosting"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c" # Built-in allowed location definition

  display_name = "Enforce Asia-Pacific Data Residency"
  description  = "Deny resource creation outside of Southeast Asia / authorized compliant regions for healthcare governance."

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = ["southeastasia"]
    }
  })
}

# 2. IAM & Governance (RBAC)
# ──────────────────────────────────────────────────────────────────────────────
data "azurerm_client_config" "current" {}

# Owner Assignment (Current Developer/CI User)
resource "azurerm_role_assignment" "owner" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Restrict human access — Everyone else in the ESMOS org is a Reader
# (Simulated via a group or default policy in practice)
resource "azurerm_role_assignment" "reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = "00000000-0000-0000-0000-000000000000" # Placeholder for ESMOS Technical Team group
}

# System-to-System Identity
# ACA Managed Identity: Needs Contributor to manage its own revisions and network links
resource "azurerm_role_assignment" "aca_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

# Monitoring Identity
# Grafana Managed Identity: Only needs to read metrics and logs
resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Monitoring Reader"
  principal_id         = "11111111-1111-1111-1111-111111111111" # Placeholder for ESMOS Grafana SP
}

