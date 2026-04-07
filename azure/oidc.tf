variable "github_organization" {
  description = "The GitHub organization or username owning the repositories"
  type        = string
  default     = "esmos-health-g8t1" 
}

variable "github_repo_odoo" {
  description = "The repository name for Odoo"
  type        = string
  default     = "odoo" 
}

variable "github_repo_moodle" {
  description = "The repository name for Moodle"
  type        = string
  default     = "moodle"
}

variable "github_repo_peppermint" {
  description = "The repository name for Peppermint"
  type        = string
  default     = "peppermint"
}

resource "azurerm_federated_identity_credential" "odoo" {
  name                = "github-odoo"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.aca_identity.id
  subject             = "repo:${var.github_organization}/${var.github_repo_odoo}:ref:refs/heads/main"
}

resource "azurerm_federated_identity_credential" "moodle" {
  name                = "github-moodle"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.aca_identity.id
  subject             = "repo:${var.github_organization}/${var.github_repo_moodle}:ref:refs/heads/main"
}

resource "azurerm_federated_identity_credential" "peppermint" {
  name                = "github-peppermint"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.aca_identity.id
  subject             = "repo:${var.github_organization}/${var.github_repo_peppermint}:ref:refs/heads/main"
}
