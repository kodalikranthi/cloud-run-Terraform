# Create Google Artifact Registry repositories
resource "google_artifact_registry_repository" "repositories" {
  for_each = var.artifact_registries

  location      = var.region
  repository_id = each.value.repository_id
  description   = each.value.description
  format        = each.value.format

  depends_on = [google_project_service.required_apis]
}