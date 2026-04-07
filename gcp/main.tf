# ── Enable required APIs ──────────────────────────────────────────────────────
resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "networksecurity" {
  service            = "networksecurity.googleapis.com"
  disable_on_destroy = false
}

# ── Static global IP (Premium tier — implicit for global addresses) ────────────
resource "google_compute_global_address" "esmos" {
  name = "esmos-lb-ip"

  depends_on = [google_project_service.compute]
}

# ── sslip.io subdomain locals ─────────────────────────────────────────────────
# Derives all domains from the static IP — no manual -var='domains=[...]' needed.
# sslip.io wildcard DNS: *.34-1-2-3.sslip.io resolves to 34.1.2.3 automatically.
locals {
  ip_dashes      = replace(google_compute_global_address.esmos.address, ".", "-")
  base_domain    = "${local.ip_dashes}.sslip.io"           # Peppermint
  moodle_domain  = "moodle.${local.ip_dashes}.sslip.io"   # Moodle
  odoo_domain    = "odoo.${local.ip_dashes}.sslip.io"     # Odoo
  bridge_domain  = "bridge.${local.ip_dashes}.sslip.io"   # Bridge integration layer
}

# ── Google-managed SSL certificate ────────────────────────────────────────────
# Covers all three subdomains. Provisions automatically — sslip.io always
# resolves to the LB IP so no DNS config is required.
resource "google_compute_managed_ssl_certificate" "esmos" {
  name = "esmos-managed-cert-2"

  managed {
    domains = [local.base_domain, local.moodle_domain, local.odoo_domain, local.bridge_domain]
  }

  lifecycle {
    create_before_destroy = true
  }
}


# ── Internet NEGs (point at Azure ACA origins) ────────────────────────────────
resource "google_compute_global_network_endpoint_group" "moodle" {
  name                  = "moodle-neg"
  network_endpoint_type = "INTERNET_FQDN_PORT"
  default_port          = 443

  depends_on = [google_project_service.compute]
}

resource "google_compute_global_network_endpoint" "moodle" {
  global_network_endpoint_group = google_compute_global_network_endpoint_group.moodle.name
  fqdn                          = var.moodle_aca_fqdn
  port                          = 443
}

resource "google_compute_global_network_endpoint_group" "odoo" {
  name                  = "odoo-neg"
  network_endpoint_type = "INTERNET_FQDN_PORT"
  default_port          = 443

  depends_on = [google_project_service.compute]
}

resource "google_compute_global_network_endpoint" "odoo" {
  global_network_endpoint_group = google_compute_global_network_endpoint_group.odoo.name
  fqdn                          = var.odoo_aca_fqdn
  port                          = 443
}

resource "google_compute_global_network_endpoint_group" "peppermint" {
  name                  = "peppermint-neg"
  network_endpoint_type = "INTERNET_FQDN_PORT"
  default_port          = 443

  depends_on = [google_project_service.compute]
}

resource "google_compute_global_network_endpoint" "peppermint" {
  global_network_endpoint_group = google_compute_global_network_endpoint_group.peppermint.name
  fqdn                          = var.peppermint_aca_fqdn
  port                          = 443
}

resource "google_compute_global_network_endpoint_group" "bridge" {
  name                  = "bridge-neg"
  network_endpoint_type = "INTERNET_FQDN_PORT"
  default_port          = 443

  depends_on = [google_project_service.compute]
}

resource "google_compute_global_network_endpoint" "bridge" {
  global_network_endpoint_group = google_compute_global_network_endpoint_group.bridge.name
  fqdn                          = var.bridge_aca_fqdn
  port                          = 443
}

# ── Backend services ──────────────────────────────────────────────────────────
# Health checks are NOT supported on Internet NEGs — omitted intentionally.
resource "google_compute_backend_service" "moodle" {
  name                  = "moodle-backend"
  protocol              = "HTTPS"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_global_network_endpoint_group.moodle.id
  }
}

resource "google_compute_backend_service" "odoo" {
  name                  = "odoo-backend"
  protocol              = "HTTPS"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_global_network_endpoint_group.odoo.id
  }
}

resource "google_compute_backend_service" "peppermint" {
  name                  = "peppermint-backend"
  protocol              = "HTTPS"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_global_network_endpoint_group.peppermint.id
  }
}

resource "google_compute_backend_service" "bridge" {
  name                  = "bridge-backend"
  protocol              = "HTTPS"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_global_network_endpoint_group.bridge.id
  }
}

# ── URL map (subdomain-based routing) ────────────────────────────────────────
# Each app gets its own subdomain so it serves from / — avoids redirect-loop
# issues caused by apps generating absolute URLs that don't match path prefixes.
resource "google_compute_url_map" "esmos" {
  name            = "esmos-url-map"
  default_service = google_compute_backend_service.peppermint.id

  # moodle.34-x-x-x.sslip.io → Moodle backend
  host_rule {
    hosts        = [local.moodle_domain]
    path_matcher = "moodle"
  }

  # odoo.34-x-x-x.sslip.io → Odoo backend
  host_rule {
    hosts        = [local.odoo_domain]
    path_matcher = "odoo"
  }

  # bridge.34-x-x-x.sslip.io → Bridge integration layer
  host_rule {
    hosts        = [local.bridge_domain]
    path_matcher = "bridge"
  }

  # 34-x-x-x.sslip.io (catch-all) → Peppermint backend
  host_rule {
    hosts        = ["*"]
    path_matcher = "peppermint"
  }

  path_matcher {
    name            = "moodle"
    default_service = google_compute_backend_service.moodle.id
    default_route_action {
      url_rewrite {
        host_rewrite = var.moodle_aca_fqdn
      }
    }
  }

  path_matcher {
    name            = "odoo"
    default_service = google_compute_backend_service.odoo.id
    default_route_action {
      url_rewrite {
        host_rewrite = var.odoo_aca_fqdn
      }
    }
  }

  path_matcher {
    name            = "peppermint"
    default_service = google_compute_backend_service.peppermint.id
    default_route_action {
      url_rewrite {
        host_rewrite = var.peppermint_aca_fqdn
      }
    }
  }

  path_matcher {
    name            = "bridge"
    default_service = google_compute_backend_service.bridge.id
    default_route_action {
      url_rewrite {
        host_rewrite = var.bridge_aca_fqdn
      }
    }
  }
}

# ── HTTP → HTTPS redirect ─────────────────────────────────────────────────────
resource "google_compute_url_map" "https_redirect" {
  name = "esmos-https-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "redirect" {
  name    = "esmos-http-proxy"
  url_map = google_compute_url_map.https_redirect.id
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "esmos-http-forwarding"
  ip_address            = google_compute_global_address.esmos.address
  port_range            = "80"
  target                = google_compute_target_http_proxy.redirect.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# ── HTTPS proxy + forwarding rule ─────────────────────────────────────────────
resource "google_compute_target_https_proxy" "esmos" {
  name             = "esmos-https-proxy"
  url_map          = google_compute_url_map.esmos.id
  ssl_certificates = [google_compute_managed_ssl_certificate.esmos.id]
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = "esmos-https-forwarding"
  ip_address            = google_compute_global_address.esmos.address
  port_range            = "443"
  target                = google_compute_target_https_proxy.esmos.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
