output "metabase_service_url" {
  description = "Private URL for the Metabase service."
  value       = google_cloud_run_v2_service.metabase.uri
}

output "metabase_service_account_email" {
  description = "Email of the Metabase service account."
  value       = google_service_account.metabase.email
}
