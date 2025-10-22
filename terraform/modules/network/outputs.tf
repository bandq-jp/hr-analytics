output "network_id" {
  description = "ID of the VPC network."
  value       = google_compute_network.analytics.id
}

output "network_name" {
  description = "Name of the VPC network."
  value       = google_compute_network.analytics.name
}

output "subnet_id" {
  description = "ID of the VPC subnet."
  value       = google_compute_subnetwork.analytics.id
}

output "connector_id" {
  description = "ID of the VPC Access connector."
  value       = google_vpc_access_connector.serverless.id
}
