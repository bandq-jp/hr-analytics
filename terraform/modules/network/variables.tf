variable "region" {
  description = "Default GCP region for resources."
  type        = string
}

variable "network_name" {
  description = "Name for the VPC network."
  type        = string
  default     = "ha-analytics-network"
}

variable "subnet_name" {
  description = "Name for the VPC subnet."
  type        = string
  default     = "ha-analytics-subnet"
}

variable "vpc_cidr" {
  description = "CIDR range for the custom VPC subnetwork."
  type        = string
  default     = "10.90.0.0/24"
}

variable "connector_name" {
  description = "Name for the VPC Access connector."
  type        = string
  default     = "ha-serverless-connector"
}

variable "connector_cidr" {
  description = "CIDR block allocated to the Serverless VPC Access connector."
  type        = string
  default     = "10.8.0.0/28"
}

variable "project_services" {
  description = "Map of enabled project services."
  type        = any
}
