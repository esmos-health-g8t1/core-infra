variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region — asia-southeast1 matches Azure Southeast Asia"
  type        = string
  default     = "asia-southeast1"
}

variable "moodle_aca_fqdn" {
  description = "ACA hostname for Moodle (no https://)"
  type        = string
  default     = "moodle-app.bluegrass-c2c68e89.southeastasia.azurecontainerapps.io"
}

variable "odoo_aca_fqdn" {
  description = "ACA hostname for Odoo (no https://)"
  type        = string
  default     = "odoo-app.bluegrass-c2c68e89.southeastasia.azurecontainerapps.io"
}

variable "peppermint_aca_fqdn" {
  description = "ACA hostname for Peppermint (no https://)"
  type        = string
  default     = "peppermint-app.bluegrass-c2c68e89.southeastasia.azurecontainerapps.io"
}

variable "bridge_aca_fqdn" {
  description = "ACA hostname for the Bridge integration layer (no https://)"
  type        = string
  default     = "bridge-app.bluegrass-c2c68e89.southeastasia.azurecontainerapps.io"
}

