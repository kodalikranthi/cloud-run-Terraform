# IAM: Cloud Run service accounts for each service
resource "google_service_account" "cloudrun" {
  for_each = var.cloud_run_services

  account_id   = "${each.value.name}-sa"
  display_name = "Cloud Run Service Account for ${each.value.name}"
}

# IAM: Grant Cloud Run service accounts access to secrets
resource "google_secret_manager_secret_iam_member" "cloudrun_secrets" {
  for_each = local.all_secrets

  secret_id = google_secret_manager_secret.secrets[each.key].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun[keys(var.cloud_run_services)[0]].email}"
}

# IAM: Grant Cloud Run service accounts access to KMS
resource "google_kms_crypto_key_iam_member" "cloudrun_kms" {
  for_each = var.cloud_run_services

  crypto_key_id = google_kms_crypto_key.keys["main"].id
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  member        = "serviceAccount:${google_service_account.cloudrun[each.key].email}"
}

# IAM: Grant Cloud Run service accounts access to Artifact Registry
resource "google_artifact_registry_repository_iam_member" "cloudrun_gar" {
  for_each = var.cloud_run_services

  location   = google_artifact_registry_repository.repositories["main"].location
  repository = google_artifact_registry_repository.repositories["main"].name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.cloudrun[each.key].email}"
}

# IAM: Grant Cloud Run invoker role to the service accounts
resource "google_cloud_run_v2_service_iam_member" "cloudrun_invoker" {
  for_each = var.cloud_run_services

  location = google_cloud_run_v2_service.services[each.key].location
  name     = google_cloud_run_v2_service.services[each.key].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.cloudrun[each.key].email}"
}

# IAM: Grant Spanner database user permissions to Cloud Run service accounts (only if Spanner instances are configured)
resource "google_spanner_database_iam_member" "cloudrun_spanner" {
  for_each = length(var.spanner_instances) > 0 ? var.spanner_instances : {}

  instance = each.value.instance_id
  database = each.value.database_id
  role     = "roles/spanner.databaseUser"
  member   = "serviceAccount:${google_service_account.cloudrun[keys(var.cloud_run_services)[0]].email}"
}

# IAM: Grant necessary roles to the default compute service account for load balancer
resource "google_project_iam_member" "compute_service_agent" {
  project = var.project_id
  role    = "roles/compute.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com"
}

# IAM: Grant necessary roles for certificate management
resource "google_project_iam_member" "certificate_manager_admin" {
  project = var.project_id
  role    = "roles/certificatemanager.admin"
  member  = "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com"
}

# IAM: Grant necessary roles for load balancer management
resource "google_project_iam_member" "compute_network_admin" {
  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com"
}