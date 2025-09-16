# Create backend services for each Cloud Run service
resource "google_compute_backend_service" "backends" {
  for_each = var.cloud_run_services

  name        = "${each.value.name}-backend"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.cloudrun_negs[each.key].id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# Create managed SSL certificates (only if domains are provided)
resource "google_compute_managed_ssl_certificate" "certificates" {
  for_each = length(var.ssl_certificates) > 0 ? var.ssl_certificates : {}

  name = "${each.key}-ssl-cert"

  managed {
    domains = each.value.domains
  }
}

# Create URL map
resource "google_compute_url_map" "main" {
  name            = "cloud-run-urlmap"
  default_service = google_compute_backend_service.backends[keys(var.cloud_run_services)[0]].id

  # Add host rules for each SSL certificate (only if certificates exist)
  dynamic "host_rule" {
    for_each = length(var.ssl_certificates) > 0 ? var.ssl_certificates : {}
    content {
      hosts        = host_rule.value.domains
      path_matcher = "${host_rule.key}-paths"
    }
  }

  # Add path matchers for each certificate (only if certificates exist)
  dynamic "path_matcher" {
    for_each = length(var.ssl_certificates) > 0 ? var.ssl_certificates : {}
    content {
      name            = "${path_matcher.key}-paths"
      default_service = google_compute_backend_service.backends[keys(var.cloud_run_services)[0]].id
    }
  }
}

# Create target HTTPS proxy (only if SSL certificates exist)
resource "google_compute_target_https_proxy" "main" {
  count = length(var.ssl_certificates) > 0 ? 1 : 0

  name             = "cloud-run-https-proxy"
  url_map          = google_compute_url_map.main.id
  ssl_certificates = [for cert in google_compute_managed_ssl_certificate.certificates : cert.id]
}

# Create target HTTP proxy (fallback when no SSL certificates)
resource "google_compute_target_http_proxy" "main" {
  count = length(var.ssl_certificates) == 0 ? 1 : 0

  name    = "cloud-run-http-proxy"
  url_map = google_compute_url_map.main.id
}

# Create forwarding rule for internal load balancer (HTTPS)
resource "google_compute_forwarding_rule" "main_https" {
  count = length(var.ssl_certificates) > 0 ? 1 : 0

  name                  = "cloud-run-forwarding-rule-https"
  target                = google_compute_target_https_proxy.main[0].id
  port_range            = "443"
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = data.google_compute_network.load_balancer_network.id
  subnetwork            = data.google_compute_subnetwork.load_balancer_subnet.id
  ip_address            = local.load_balancer_ip
}

# Create forwarding rule for internal load balancer (HTTP)
resource "google_compute_forwarding_rule" "main_http" {
  count = length(var.ssl_certificates) == 0 ? 1 : 0

  name                  = "cloud-run-forwarding-rule-http"
  target                = google_compute_target_http_proxy.main[0].id
  port_range            = "80"
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = data.google_compute_network.load_balancer_network.id
  subnetwork            = data.google_compute_subnetwork.load_balancer_subnet.id
  ip_address            = local.load_balancer_ip
}