output "cloud_run_services" {
  description = "Map of Cloud Run services with their URLs"
  value = {
    for key, service in google_cloud_run_v2_service.services : key => {
      name = service.name
      url  = service.uri
    }
  }
}

output "internal_load_balancer_ip" {
  description = "Internal IP address of the load balancer"
  value       = local.load_balancer_ip
}

output "internal_load_balancer_static_ip" {
  description = "Static IP address details for the load balancer"
  value = var.internal_load_balancer.create_static_ip ? {
    name    = google_compute_address.internal_lb_static[0].name
    address = google_compute_address.internal_lb_static[0].address
    region  = google_compute_address.internal_lb_static[0].region
    status  = google_compute_address.internal_lb_static[0].status
  } : null
}

output "internal_load_balancer_forwarding_rule" {
  description = "Internal load balancer forwarding rule details"
  value = {
    name      = google_compute_forwarding_rule.internal_lb_https.name
    ip_address = var.internal_load_balancer.ip_address != null ? var.internal_load_balancer.ip_address : local.load_balancer_ip
    port_range = "443"
    target    = google_compute_target_https_proxy.internal_lb.name
  }
}

output "internal_load_balancer_url_map" {
  description = "Internal load balancer URL map details"
  value = {
    name = google_compute_url_map.internal_lb.name
    services = {
      for key, service in var.internal_load_balancer.services : key => {
        service_name = service.service_name
        path         = service.path
        backend_service = google_compute_backend_service.backends[key].name
      }
    }
  }
}

output "artifact_registries" {
  description = "Map of Artifact Registry repositories"
  value = {
    for key, repo in google_artifact_registry_repository.repositories : key => {
      name     = repo.name
      location = repo.location
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

output "ssl_certificates" {
  description = "Map of SSL certificates"
  value = {
    for key, cert in google_compute_managed_ssl_certificate.certificates : key => {
      name    = cert.name
      domains = cert.managed[0].domains
    }
  }
}

output "load_balancer_forwarding_rule" {
  description = "Load balancer forwarding rule name"
  value       = length(var.ssl_certificates) > 0 ? google_compute_forwarding_rule.main_https[0].name : google_compute_forwarding_rule.main_http[0].name
}

output "spanner_instances" {
  description = "Map of Spanner instances configured"
  value       = var.spanner_instances
}