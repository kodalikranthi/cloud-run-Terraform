variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "australia-southeast2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Cloud Run Services Configuration
variable "cloud_run_services" {
  description = "Map of Cloud Run services to create"
  type = map(object({
    name             = string
    image_name       = string
    image_tag        = string
    cpu_limit        = string
    memory_limit     = string
    min_instances    = number
    max_instances    = number
    environment_vars = map(string)
    secret_names     = list(string) # List of secret names to reference from Secret Manager
  }))
  default = {
    "app" = {
      name          = "cloud-run-app"
      image_name    = "app"
      image_tag     = "latest"
      cpu_limit     = "1"
      memory_limit  = "512Mi"
      min_instances = 1
      max_instances = 10
      environment_vars = {
        "ENVIRONMENT" = "dev"
        "LOG_LEVEL"   = "info"
        "PORT"        = "8080"
      }
      secret_names = ["DATABASE_URL", "API_KEY", "JWT_SECRET"]
    }
    "api" = {
      name          = "cloud-run-api"
      image_name    = "api"
      image_tag     = "v1.0"
      cpu_limit     = "2"
      memory_limit  = "1Gi"
      min_instances = 1
      max_instances = 20
      environment_vars = {
        "ENVIRONMENT" = "dev"
        "API_VERSION" = "v1"
        "PORT"        = "8080"
      }
      secret_names = ["API_SECRET", "DB_PASSWORD"]
    }
  }
}

# Secrets Configuration for Secret Manager
variable "secrets" {
  description = "Map of secrets to create in Secret Manager"
  type        = map(string)
  default = {
    "DATABASE_URL" = "postgresql://user:password@localhost:5432/dbname"
    "API_KEY"      = "your-api-key-here"
    "JWT_SECRET"   = "your-jwt-secret-here"
    "API_SECRET"   = "your-api-secret-here"
    "DB_PASSWORD"  = "your-db-password-here"
    "REDIS_URL"    = "redis://localhost:6379"
    # Note: ssl-certificate secret should be created manually outside of Terraform
  }
}

# Network Configuration
variable "existing_vpc_network" {
  description = "Name of existing VPC network"
  type        = string
  default     = "default"
}

variable "existing_vpc_subnet" {
  description = "Name of existing VPC subnet"
  type        = string
  default     = "default"
}

variable "vpc_access_connector_name" {
  description = "Name of existing VPC access connector"
  type        = string
  default     = "vpc-connector"
}

variable "vpc_access_connector_region" {
  description = "Region of existing VPC access connector"
  type        = string
  default     = "australia-southeast2"
}

# Load Balancer Configuration
variable "load_balancer_network" {
  description = "Network name for load balancer"
  type        = string
  default     = "default"
}

variable "load_balancer_subnet" {
  description = "Subnet name for load balancer"
  type        = string
  default     = "default"
}

variable "load_balancer_ip_address" {
  description = "IP address for load balancer (optional)"
  type        = string
  default     = null
}

# Internal Load Balancer Configuration
variable "internal_load_balancer" {
  description = "Configuration for internal load balancer with HTTPS"
  type = object({
    name                   = string
    ip_address             = optional(string)
    create_static_ip       = optional(bool, false)
    static_ip_address      = optional(string)
    ssl_certificate_secrets = list(string)
    hosts                  = optional(list(string), ["*"])
    services = map(object({
      service_name = string
      path         = string
    }))
  })
  default = {
    name                   = "internal-lb"
    create_static_ip       = false
    ssl_certificate_secrets = ["ssl-certificate"]
    services = {
      "app" = {
        service_name = "cloud-run-app"
        path         = "/app/*"
      }
      "api" = {
        service_name = "cloud-run-api"
        path         = "/api/*"
      }
    }
  }
}

# SSL Certificate Configuration (deprecated - use internal_load_balancer.ssl_certificate_secret)
variable "ssl_certificates" {
  description = "Map of SSL certificates to create (deprecated - use internal_load_balancer.ssl_certificate_secret)"
  type = map(object({
    domains = list(string)
  }))
  default = {}
}

# Spanner Configuration
variable "spanner_instances" {
  description = "Map of Spanner instances for database access"
  type = map(object({
    instance_id = string
    database_id = string
  }))
  default = {
    "main" = {
      instance_id = "my-spanner-instance"
      database_id = "my-database"
    }
    "analytics" = {
      instance_id = "analytics-spanner-instance"
      database_id = "analytics-database"
    }
  }
}

# Artifact Registry Configuration
variable "artifact_registries" {
  description = "Map of Artifact Registry repositories to create"
  type = map(object({
    repository_id = string
    description   = string
    format        = string
  }))
  default = {
    "main" = {
      repository_id = "cloud-run-repo"
      description   = "Docker repository for Cloud Run services"
      format        = "DOCKER"
    }
    "npm" = {
      repository_id = "npm-repo"
      description   = "NPM repository for Node.js packages"
      format        = "NPM"
    }
  }
}

# KMS Configuration
variable "kms_key_rings" {
  description = "Map of KMS key rings to create"
  type = map(object({
    location = string
  }))
  default = {
    "main" = {
      location = "australia-southeast2"
    }
    "backup" = {
      location = "australia-southeast1"
    }
  }
}

variable "kms_keys" {
  description = "Map of KMS keys to create"
  type = map(object({
    key_ring_name   = string
    rotation_period = string
  }))
  default = {
    "main" = {
      key_ring_name   = "main"
      rotation_period = "7776000s" # 90 days
    }
    "backup" = {
      key_ring_name   = "backup"
      rotation_period = "15552000s" # 180 days
    }
  }
}