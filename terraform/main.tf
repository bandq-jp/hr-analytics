terraform {
  required_version = ">= 1.5.0"

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

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}


locals {
  required_services = [
    "compute.googleapis.com",
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudscheduler.googleapis.com",
    "vpcaccess.googleapis.com",
    "servicemanagement.googleapis.com",
    "servicecontrol.googleapis.com",
    "iam.googleapis.com",
  ]
}

resource "google_project_service" "enabled" {
  for_each = toset(local.required_services)

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

module "network" {
  source = "./modules/network"

  region            = var.region
  network_name      = "ha-analytics-network"
  subnet_name       = "ha-analytics-subnet"
  vpc_cidr          = var.vpc_cidr
  connector_name    = "ha-serverless-connector"
  connector_cidr    = var.connector_cidr
  project_services  = google_project_service.enabled
}

module "database" {
  source = "./modules/database"

  region                      = var.region
  network_id                  = module.network.network_id
  database_instance_name      = var.database_instance_name
  database_name               = var.database_name
  database_user               = var.database_user
  database_password           = var.database_password
  metabase_database_name      = var.metabase_database_name
  metabase_database_user      = var.metabase_database_user
  metabase_database_password  = var.metabase_database_password
  database_tier               = var.database_tier
  enable_deletion_protection  = var.enable_deletion_protection
  project_services            = google_project_service.enabled
}


module "app" {
  source = "./modules/app"

  project_id                  = var.project_id
  region                      = var.region
  app_image                   = var.app_image
  database_name               = var.database_name
  database_user               = var.database_user
  database_password           = var.database_password
  database_private_ip         = module.database.private_ip_address
  supabase_url                = var.supabase_url
  supabase_service_role_key   = var.supabase_service_role_key
  app_timezone                = var.app_timezone
  ingest_schedule             = var.ingest_schedule
  transform_schedule          = var.transform_schedule
  connector_id                = module.network.connector_id
}

module "metabase" {
  source = "./modules/metabase"

  project_id                  = var.project_id
  region                      = var.region
  metabase_image              = var.metabase_image
  metabase_database_name      = var.metabase_database_name
  metabase_database_user      = var.metabase_database_user
  metabase_database_password  = var.metabase_database_password
  database_private_ip         = module.database.private_ip_address
  connector_id                = module.network.connector_id
}

