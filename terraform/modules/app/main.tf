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

data "google_project" "current" {}

locals {
  scheduler_headers = {
    "Content-Type" = "application/json"
  }
}

resource "google_service_account" "app" {
  account_id   = "sa-ha-app"
  display_name = "Hiring Analytics App"
}

resource "google_service_account" "scheduler" {
  account_id   = "sa-ha-scheduler"
  display_name = "Hiring Analytics Scheduler"
}

resource "google_project_iam_member" "app_roles" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.app.email}"
}

resource "google_project_iam_member" "scheduler_roles" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.scheduler.email}"
}

resource "google_secret_manager_secret" "supabase_key" {
  secret_id = "ha-supabase-key"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "app_database_url" {
  secret_id = "ha-database-url"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "supabase_key" {
  secret      = google_secret_manager_secret.supabase_key.id
  secret_data = var.supabase_service_role_key
}

resource "google_secret_manager_secret_version" "app_database_url" {
  secret = google_secret_manager_secret.app_database_url.id
  secret_data = "postgresql://${var.database_user}:${urlencode(var.database_password)}@${var.database_private_ip}:5432/${var.database_name}"
}

resource "google_secret_manager_secret_iam_member" "supabase_key_app" {
  secret_id = google_secret_manager_secret.supabase_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app.email}"
}

resource "google_secret_manager_secret_iam_member" "database_url_app" {
  secret_id = google_secret_manager_secret.app_database_url.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app.email}"
}

resource "google_secret_manager_secret_iam_member" "database_url_scheduler" {
  secret_id = google_secret_manager_secret.app_database_url.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.scheduler.email}"
}

resource "google_cloud_run_v2_service" "app" {
  provider = google-beta

  name     = "ha-app"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.app.email
    timeout         = "900s"

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    containers {
      image = var.app_image

      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }


      startup_probe {
        http_get {
          path = "/healthz"
          port = 8080
        }
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 30
      }

      liveness_probe {
        http_get {
          path = "/healthz"
          port = 8080
        }
        initial_delay_seconds = 30
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3
      }

      env {
        name  = "GCP_PROJECT"
        value = var.project_id
      }

      env {
        name  = "GCP_REGION"
        value = var.region
      }

      env {
        name  = "SUPABASE_URL"
        value = var.supabase_url
      }

      env {
        name  = "APP_TIMEZONE"
        value = var.app_timezone
      }

      env {
        name = "SUPABASE_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.supabase_key.name
            version = google_secret_manager_secret_version.supabase_key.version
          }
        }
      }

      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.app_database_url.name
            version = google_secret_manager_secret_version.app_database_url.version
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
    google_secret_manager_secret_version.supabase_key,
    google_secret_manager_secret_version.app_database_url,
  ]
}

resource "google_service_account_iam_member" "scheduler_token_creator" {
  service_account_id = google_service_account.scheduler.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

resource "google_cloud_run_service_iam_member" "app_scheduler" {
  service  = google_cloud_run_v2_service.app.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler.email}"

  depends_on = [google_cloud_run_v2_service.app]
}

resource "google_cloud_scheduler_job" "ingest" {
  name      = "ha-ingest"
  schedule  = var.ingest_schedule
  time_zone = var.app_timezone

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_v2_service.app.uri}/ingest/run"
    headers     = local.scheduler_headers

    oidc_token {
      service_account_email = google_service_account.scheduler.email
    }
  }

  depends_on = [
    google_cloud_run_v2_service.app,
    google_service_account.scheduler,
  ]
}

resource "google_cloud_scheduler_job" "transform" {
  name      = "ha-transform"
  schedule  = var.transform_schedule
  time_zone = var.app_timezone

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_v2_service.app.uri}/transform/run"
    headers     = local.scheduler_headers

    oidc_token {
      service_account_email = google_service_account.scheduler.email
    }
  }

  depends_on = [
    google_cloud_run_v2_service.app,
    google_service_account.scheduler,
  ]
}
