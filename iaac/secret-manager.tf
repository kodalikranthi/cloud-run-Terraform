# Create secrets in Secret Manager with KMS encryption
resource "google_secret_manager_secret" "secrets" {
  for_each = local.all_secrets

  secret_id = each.key

  replication {
    user_managed {
      replicas {
        location = var.region
        customer_managed_encryption {
          kms_key_name = google_kms_crypto_key.keys["main"].id
        }
      }
    }
  }

  depends_on = [google_project_service.required_apis]
}

# Add secret versions
resource "google_secret_manager_secret_version" "secrets" {
  for_each = local.all_secrets

  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value
}