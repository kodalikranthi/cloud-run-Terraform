# Local values for consistent naming and configuration
locals {
  # Common tags/labels
  common_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }

  # API services to enable
  required_apis = [
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "certificatemanager.googleapis.com",
    "logging.googleapis.com",
    "spanner.googleapis.com"
  ]

  # All secrets from the secrets variable
  all_secrets = var.secrets

  # Flatten all domains from SSL certificates
  all_ssl_domains = flatten([
    for cert_key, cert in var.ssl_certificates : cert.domains
  ])
}