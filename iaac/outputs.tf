output "cloud_run_services" {
  description = "Map of Cloud Run services with their URLs"
  value = {
    for key, service in google_cloud_run_v2_service.services : key => {
      name = service.name
      url  = service.uri
    }
  }
}


output "artifact_registries" {
  description = "Map of Artifact Registry repositories"
  value = {
    for key, repo in google_artifact_registry_repository.repositories : key => {
      name         = repo.name
      location     = repo.location
      registry_uri = "${var.region}-docker.pkg.dev/${var.project_id}/${repo.repository_id}"
    }
  }
}

output "kms_key_rings" {
  description = "Map of KMS key rings"
  value = {
    for key, keyring in google_kms_key_ring.key_rings : key => {
      name     = keyring.name
      location = keyring.location
    }
  }
}

output "kms_keys" {
  description = "Map of KMS keys"
  value = {
    for key, kms_key in google_kms_crypto_key.keys : key => {
      name = kms_key.name
    }
  }
}

output "secrets_created" {
  description = "List of created secrets"
  value       = keys(local.all_secrets)
}

output "cloud_run_service_accounts" {
  description = "Map of Cloud Run service accounts"
  value = {
    for key, sa in google_service_account.cloudrun : key => {
      name  = sa.name
      email = sa.email
    }
  }
}

output "vpc_network" {
  description = "VPC network name"
  value       = data.google_compute_network.existing_vpc.name
}

output "vpc_subnet" {
  description = "VPC subnet name"
  value       = data.google_compute_subnetwork.existing_subnet.name
}

output "vpc_access_connector" {
  description = "VPC access connector name"
  value       = var.vpc_access_connector_name != "" ? data.google_vpc_access_connector.existing_connector[0].name : null
}


output "spanner_instances" {
  description = "Map of Spanner instances configured"
  value       = var.spanner_instances
}