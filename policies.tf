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

