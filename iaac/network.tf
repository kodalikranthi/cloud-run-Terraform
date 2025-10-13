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

# Data source for load balancer network
data "google_compute_network" "load_balancer_network" {
  name = var.load_balancer_network
}

# Data source for load balancer subnet
data "google_compute_subnetwork" "load_balancer_subnet" {
  name   = var.load_balancer_subnet
  region = var.region
}

# Reserve static internal IP address for load balancer
resource "google_compute_address" "internal_lb_static" {
  count        = var.internal_load_balancer.create_static_ip ? 1 : 0
  name         = "${var.internal_load_balancer.name}-static-ip"
  address_type = "INTERNAL"
  subnetwork   = data.google_compute_subnetwork.load_balancer_subnet.id
  region       = var.region
  address      = var.internal_load_balancer.static_ip_address
}

# Reserve internal IP address for load balancer (if not provided and not using static IP)
resource "google_compute_address" "internal_lb" {
  count        = var.load_balancer_ip_address == null && !var.internal_load_balancer.create_static_ip ? 1 : 0
  name         = "internal-lb-ip"
  address_type = "INTERNAL"
  subnetwork   = data.google_compute_subnetwork.load_balancer_subnet.id
  region       = var.region
}

# Use existing IP address if provided, otherwise use static IP or dynamic IP
locals {
  load_balancer_ip = var.load_balancer_ip_address != null ? var.load_balancer_ip_address : (
    var.internal_load_balancer.create_static_ip ? google_compute_address.internal_lb_static[0].address : google_compute_address.internal_lb[0].address
  )
}