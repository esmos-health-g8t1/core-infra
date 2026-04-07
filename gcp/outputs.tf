output "front_door_ip" {
  description = "Static global IP — use this to form your sslip.io domain (e.g. 34.1.2.3 → 34-1-2-3.sslip.io)"
  value       = google_compute_global_address.esmos.address
}


output "backend_service_names" {
  description = "Backend service names per app"
  value = {
    moodle     = google_compute_backend_service.moodle.name
    odoo       = google_compute_backend_service.odoo.name
    peppermint = google_compute_backend_service.peppermint.name
  }
}

output "moodle_url" {
  description = "Moodle via GCP edge"
  value       = "https://${local.moodle_domain}/"
}

output "odoo_url" {
  description = "Odoo via GCP edge"
  value       = "https://${local.odoo_domain}/"
}

output "peppermint_url" {
  description = "Peppermint via GCP edge"
  value       = "https://${local.base_domain}/"
}
