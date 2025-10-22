variable "project_id" {
  description = "Target GCP project ID."
  type        = string
}

variable "region" {
  description = "Default GCP region for resources."
  type        = string
}

variable "metabase_image" {
  description = "Container image URI for Metabase."
  type        = string
  default     = "metabase/metabase:v0.48.6"
}

variable "metabase_database_name" {
  description = "Database used by Metabase to store metadata."
  type        = string
  default     = "metabase_meta"
}

variable "metabase_database_user" {
  description = "Database user for the Metabase metadata database."
  type        = string
  default     = "metabase_user"
}

variable "metabase_database_password" {
  description = "Password for the Metabase database user."
  type        = string
  sensitive   = true
}

variable "database_private_ip" {
  description = "Private IP address of the Cloud SQL instance."
  type        = string
}

variable "connector_id" {
  description = "ID of the VPC Access connector."
  type        = string
}
