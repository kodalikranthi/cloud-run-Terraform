# Create Google Artifact Registry repositories
resource "google_artifact_registry_repository" "repositories" {
  for_each = var.artifact_registries

  location      = var.region
  repository_id = each.value.repository_id
  description   = each.value.description
  format        = each.value.format

  # KMS encryption for GAR
  kms_key_name = google_kms_crypto_key.gar_encryption_key.id

  # Docker configuration with immutable tags
  docker_config {
    immutable_tags = true
  }

  # Labels for GAR - merge common labels with GAR-specific labels
  labels = merge(local.common_labels, each.value.labels)

  depends_on = [google_project_service.required_apis]
}