variable "project_id" {
  description = "Target GCP project ID."
  type        = string
}

variable "region" {
  description = "Default GCP region for resources."
  type        = string
}

variable "app_image" {
  description = "Container image URI for the FastAPI ingestion service."
  type        = string
}

variable "database_name" {
  description = "Primary analytics database name."
  type        = string
}

variable "database_user" {
  description = "Application database user."
  type        = string
}

variable "database_password" {
  description = "Password for the application database user."
  type        = string
  sensitive   = true
}

variable "database_private_ip" {
  description = "Private IP address of the Cloud SQL instance."
  type        = string
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

variable "connector_id" {
  description = "ID of the VPC Access connector."
  type        = string
}
