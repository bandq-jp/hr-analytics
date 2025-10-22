terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.30"
    }
  }
}

resource "google_compute_network" "analytics" {
  name                    = var.network_name
  auto_create_subnetworks = false

  depends_on = [var.project_services]
}

resource "google_compute_subnetwork" "analytics" {
  name          = var.subnet_name
  region        = var.region
  network       = google_compute_network.analytics.id
  ip_cidr_range = var.vpc_cidr
}

resource "google_vpc_access_connector" "serverless" {
  provider = google-beta

  name          = var.connector_name
  region        = var.region
  network       = google_compute_network.analytics.name
  ip_cidr_range = var.connector_cidr
}

resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.analytics.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.analytics.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}
