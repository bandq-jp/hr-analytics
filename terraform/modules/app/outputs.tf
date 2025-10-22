output "app_service_url" {
  description = "Public URL for the FastAPI ingestion service."
  value       = google_cloud_run_v2_service.app.uri
}

output "app_service_account_email" {
  description = "Email of the app service account."
  value       = google_service_account.app.email
}

output "scheduler_service_account_email" {
  description = "Email of the scheduler service account."
  value       = google_service_account.scheduler.email
}
