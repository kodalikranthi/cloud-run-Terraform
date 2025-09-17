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
    "logging.googleapis.com",
    "spanner.googleapis.com"
  ]

  # All secrets from the secrets variable
  all_secrets = var.secrets
}