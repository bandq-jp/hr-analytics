variable "region" {
  description = "Default GCP region for resources."
  type        = string
}

variable "network_id" {
  description = "ID of the VPC network."
  type        = string
}

variable "database_instance_name" {
  description = "Cloud SQL instance identifier."
  type        = string
  default     = "ha-analytics"
}

variable "database_name" {
  description = "Primary analytics database name."
  type        = string
  default     = "analytics_app"
}

variable "database_user" {
  description = "Application database user."
  type        = string
  default     = "app_user"
}

variable "database_password" {
  description = "Password for the application database user."
  type        = string
  sensitive   = true
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

variable "database_tier" {
  description = "Machine tier for Cloud SQL."
  type        = string
  default     = "db-custom-1-3840"
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection on the Cloud SQL instance."
  type        = bool
  default     = true
}

variable "project_services" {
  description = "Map of enabled project services."
  type        = any
}

variable "private_vpc_connection" {
  description = "Private VPC connection for Cloud SQL."
  type        = any
}
