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

# Get SSL certificate from manually created Secret Manager secret
data "google_secret_manager_secret_version" "ssl_certificate" {
  secret = var.internal_load_balancer.ssl_certificate_secret
}

# Parse the SSL certificate and private key from the secret
locals {
  ssl_cert_data = data.google_secret_manager_secret_version.ssl_certificate.secret_data
  # Split the certificate and private key (assuming they are concatenated)
  ssl_cert_parts  = split("-----BEGIN PRIVATE KEY-----", local.ssl_cert_data)
  ssl_certificate = local.ssl_cert_parts[0]
  ssl_private_key = "-----BEGIN PRIVATE KEY-----${local.ssl_cert_parts[1]}"
}

# Create SSL certificate from manually created Secret Manager secret
resource "google_compute_ssl_certificate" "internal_lb_cert" {
  name        = "${var.internal_load_balancer.name}-ssl-cert"
  private_key = local.ssl_private_key
  certificate = local.ssl_certificate

  lifecycle {
    create_before_destroy = true
  }
}

# Create URL map with path-based routing for multiple services
resource "google_compute_url_map" "internal_lb" {
  name = "${var.internal_load_balancer.name}-urlmap"

  # Default service (fallback) - use first service from load balancer configuration
  default_service = google_compute_backend_service.internal_lb_backends[keys(var.internal_load_balancer.services)[0]].id

  # Path-based routing for each service
  dynamic "path_matcher" {
    for_each = var.internal_load_balancer.services
    content {
      name            = "${path_matcher.key}-matcher"
      default_service = google_compute_backend_service.internal_lb_backends[path_matcher.key].id

      # Path rules for each service
      path_rule {
        paths   = [path_matcher.value.path]
        service = google_compute_backend_service.internal_lb_backends[path_matcher.key].id
      }
    }
  }
}

# Create target HTTPS proxy
resource "google_compute_target_https_proxy" "internal_lb" {
  name             = "${var.internal_load_balancer.name}-https-proxy"
  url_map          = google_compute_url_map.internal_lb.id
  ssl_certificates = [google_compute_ssl_certificate.internal_lb_cert.id]
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