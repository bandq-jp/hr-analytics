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

resource "google_sql_database_instance" "app" {
  provider = google-beta

  name             = var.database_instance_name
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier              = var.database_tier
    availability_type = "ZONAL"

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network_id
      enable_private_path_for_google_cloud_services = true
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }
  }

  deletion_protection = var.enable_deletion_protection

  depends_on = [var.project_services]
}

resource "google_sql_database" "analytics" {
  name     = var.database_name
  instance = google_sql_database_instance.app.name
}

resource "google_sql_database" "metabase" {
  name     = var.metabase_database_name
  instance = google_sql_database_instance.app.name
}

resource "google_sql_user" "app" {
  instance = google_sql_database_instance.app.name
  name     = var.database_user
  password = var.database_password
}

resource "google_sql_user" "metabase" {
  instance = google_sql_database_instance.app.name
  name     = var.metabase_database_user
  password = var.metabase_database_password
}
