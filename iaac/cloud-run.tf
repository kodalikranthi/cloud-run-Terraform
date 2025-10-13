# Create Cloud Run services
resource "google_cloud_run_v2_service" "services" {
  for_each = var.cloud_run_services

  name     = each.value.name
  location = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repositories["main"].repository_id}/${each.value.image_name}:${each.value.image_tag}"

      # Add regular environment variables
      dynamic "env" {
        for_each = each.value.environment_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      # Add secrets as environment variables from Secret Manager
      dynamic "env" {
        for_each = each.value.secret_names
        content {
          name = env.value
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.secrets[env.value].secret_id
              version = "latest"
            }
          }
        }
      }

      resources {
        limits = {
          cpu    = each.value.cpu_limit
          memory = each.value.memory_limit
        }
      }
    }

    scaling {
      min_instance_count = each.value.min_instances
      max_instance_count = each.value.max_instances
    }

    dynamic "vpc_access" {
      for_each = var.vpc_access_connector_name != "" ? [1] : []
      content {
        connector = data.google_vpc_access_connector.existing_connector[0].id
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }
  }

  depends_on = [
    google_project_service.required_apis,
    google_artifact_registry_repository.repositories,
    google_secret_manager_secret_version.secrets
  ]
}

# Create serverless NEGs for Cloud Run services
resource "google_compute_region_network_endpoint_group" "cloudrun_negs" {
  for_each = var.cloud_run_services

  name                  = "${each.value.name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_v2_service.services[each.key].name
  }

  depends_on = [google_cloud_run_v2_service.services]
}