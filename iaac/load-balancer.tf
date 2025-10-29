# Create backend services for each service in the load balancer configuration
resource "google_compute_backend_service" "internal_lb_backends" {
  for_each = var.internal_load_balancer.services

  name        = "${each.value.service_name}-backend"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  backend {
    # Direct reference to NEG using the same key as cloud_run_services
    group = google_compute_region_network_endpoint_group.cloudrun_negs[each.key].id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  depends_on = [google_cloud_run_v2_service.services]
}

# Get SSL certificates from manually created Secret Manager secrets
data "google_secret_manager_secret_version" "ssl_certificates" {
  for_each = toset(var.internal_load_balancer.ssl_certificate_secrets)
  secret   = each.value
}

# Create SSL certificates from manually created Secret Manager secrets
resource "google_compute_ssl_certificate" "internal_lb_certs" {
  for_each = data.google_secret_manager_secret_version.ssl_certificates

  name = "${var.internal_load_balancer.name}-ssl-cert-${each.key}"
  
  # Parse and fix the certificate
  certificate = "-----BEGIN CERTIFICATE-----\n${replace(
    replace(
      replace(
        split("-----BEGIN PRIVATE KEY-----", each.value.secret_data)[0],
        "-----BEGIN CERTIFICATE-----", ""
      ),
      "-----END CERTIFICATE-----", ""
    ),
    " ", "\n"
  )}\n-----END CERTIFICATE-----"
  
  # Parse and fix the private key
  private_key = "-----BEGIN PRIVATE KEY-----\n${replace(
    replace(
      replace(
        split("-----BEGIN PRIVATE KEY-----", each.value.secret_data)[1],
        "-----BEGIN PRIVATE KEY-----", ""
      ),
      "-----END PRIVATE KEY-----", ""
    ),
    " ", "\n"
  )}\n-----END PRIVATE KEY-----"

  lifecycle {
    create_before_destroy = true
  }
}

# Create URL map with host and path-based routing for multiple services
resource "google_compute_url_map" "internal_lb" {
  name = "${var.internal_load_balancer.name}-urlmap"

  # Default service (fallback) - use first service from load balancer configuration
  default_service = google_compute_backend_service.internal_lb_backends[keys(var.internal_load_balancer.services)[0]].id

  # Host rules for all configured hosts
  host_rule {
    hosts        = var.internal_load_balancer.hosts
    path_matcher = "all-paths"
  }

  # Path matcher for all services
  path_matcher {
    name            = "all-paths"
    default_service = google_compute_backend_service.internal_lb_backends[keys(var.internal_load_balancer.services)[0]].id

    # Path rules for each service
    dynamic "path_rule" {
      for_each = var.internal_load_balancer.services
      content {
        paths   = [path_rule.value.path]
        service = google_compute_backend_service.internal_lb_backends[path_rule.key].id
      }
    }
  }
}

# Create target HTTPS proxy
resource "google_compute_target_https_proxy" "internal_lb" {
  name             = "${var.internal_load_balancer.name}-https-proxy"
  url_map          = google_compute_url_map.internal_lb.id
  ssl_certificates = [for cert in google_compute_ssl_certificate.internal_lb_certs : cert.id]
}

# Create single forwarding rule for internal load balancer (HTTPS)
resource "google_compute_forwarding_rule" "internal_lb_https" {
  name                  = "${var.internal_load_balancer.name}-forwarding-rule"
  target                = google_compute_target_https_proxy.internal_lb.id
  port_range            = "443"
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = data.google_compute_network.load_balancer_network.id
  subnetwork            = data.google_compute_subnetwork.load_balancer_subnet.id
  ip_address            = var.internal_load_balancer.ip_address != null ? var.internal_load_balancer.ip_address : local.load_balancer_ip

  depends_on = [
    google_compute_backend_service.internal_lb_backends,
    google_cloud_run_v2_service.services
  ]
}