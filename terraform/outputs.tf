output "app_service_url" {
  description = "Public URL for the FastAPI ingestion service."
  value       = module.app.app_service_url
}

output "metabase_service_url" {
  description = "Public URL for the Metabase service."
  value       = module.metabase.metabase_service_url
}

output "cloud_sql_private_ip" {
  description = "Private IP address assigned to the Cloud SQL instance."
  value       = module.database.private_ip_address
}

output "cloud_sql_instance_connection_name" {
  description = "Connection name for the Cloud SQL instance."
  value       = module.database.connection_name
}
