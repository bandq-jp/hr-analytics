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

resource "google_service_account" "metabase" {
  account_id   = "sa-ha-metabase"
  display_name = "Hiring Analytics Metabase"
}

resource "google_project_iam_member" "metabase_roles" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.metabase.email}"
}

resource "google_secret_manager_secret" "metabase_db_password" {
  secret_id = "ha-metabase-db-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "metabase_db_password" {
  secret      = google_secret_manager_secret.metabase_db_password.id
  secret_data = var.metabase_database_password
}

resource "google_secret_manager_secret_iam_member" "metabase_password_metabase" {
  secret_id = google_secret_manager_secret.metabase_db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.metabase.email}"
}

resource "google_cloud_run_v2_service" "metabase" {
  provider = google-beta

  name     = "ha-metabase"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    service_account = google_service_account.metabase.email

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      image = var.metabase_image

      resources {
        limits = {
          cpu    = "2"
          memory = "2048Mi"
        }
      }

      env {
        name  = "MB_DB_TYPE"
        value = "postgres"
      }

      env {
        name  = "MB_DB_DBNAME"
        value = var.metabase_database_name
      }

      env {
        name  = "MB_DB_HOST"
        value = var.database_private_ip
      }

      env {
        name  = "MB_DB_PORT"
        value = "5432"
      }

      env {
        name  = "MB_DB_USER"
        value = var.metabase_database_user
      }

      env {
        name = "MB_DB_PASS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.metabase_db_password.name
            version = google_secret_manager_secret_version.metabase_db_password.version
          }
        }
      }
    }

    vpc_access {
      connector = var.connector_id
      egress    = "PRIVATE_RANGES_ONLY"
    }
  }

  depends_on = [
    google_secret_manager_secret_version.metabase_db_password,
  ]
}
