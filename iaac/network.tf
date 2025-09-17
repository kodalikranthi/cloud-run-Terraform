# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset(local.required_apis)

  service            = each.value
  disable_on_destroy = false
}

# Data source for existing VPC network
data "google_compute_network" "existing_vpc" {
  name = var.existing_vpc_network
}

# Data source for existing VPC subnet
data "google_compute_subnetwork" "existing_subnet" {
  name   = var.existing_vpc_subnet
  region = var.region
}

# Data source for existing VPC access connector (optional)
data "google_vpc_access_connector" "existing_connector" {
  count = var.vpc_access_connector_name != "" ? 1 : 0

  name   = var.vpc_access_connector_name
  region = var.vpc_access_connector_region
}
