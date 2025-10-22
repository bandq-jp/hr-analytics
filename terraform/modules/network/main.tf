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
