variable "project_id" {
  description = "Target GCP project ID."
  type        = string
}

variable "region" {
  description = "Default GCP region for resources."
  type        = string
  default     = "asia-northeast1"
}

variable "app_image" {
  description = "Container image URI for the FastAPI ingestion service."
  type        = string
}

variable "metabase_image" {
  description = "Container image URI for Metabase."
  type        = string
  default     = "metabase/metabase:v0.48.6"
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
  default     = false
}

variable "supabase_url" {
  description = "Base URL for the Supabase project (https://xxx.supabase.co)."
  type        = string
}

variable "supabase_service_role_key" {
  description = "Supabase service role key used by the ingestion service."
  type        = string
  sensitive   = true
}

variable "app_timezone" {
  description = "Timezone used by the application and scheduler."
  type        = string
  default     = "Asia/Tokyo"
}

variable "ingest_schedule" {
  description = "Cron schedule for the ingest job."
  type        = string
  default     = "0 3 * * *"
}

variable "transform_schedule" {
  description = "Cron schedule for the transform job."
  type        = string
  default     = "5 3 * * *"
}

variable "vpc_cidr" {
  description = "CIDR range for the custom VPC subnetwork."
  type        = string
  default     = "10.90.0.0/24"
}

variable "connector_cidr" {
  description = "CIDR block allocated to the Serverless VPC Access connector."
  type        = string
  default     = "10.8.0.0/28"
}