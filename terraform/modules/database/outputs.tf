output "instance_name" {
  description = "Name of the Cloud SQL instance."
  value       = google_sql_database_instance.app.name
}

output "private_ip_address" {
  description = "Private IP address assigned to the Cloud SQL instance."
  value       = google_sql_database_instance.app.private_ip_address
}

output "connection_name" {
  description = "Connection name for the Cloud SQL instance."
  value       = google_sql_database_instance.app.connection_name
}

output "analytics_database_name" {
  description = "Name of the analytics database."
  value       = google_sql_database.analytics.name
}

output "metabase_database_name" {
  description = "Name of the Metabase database."
  value       = google_sql_database.metabase.name
}
