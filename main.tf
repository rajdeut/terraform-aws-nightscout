terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Get available zones in the region and select the first one
data "google_compute_zones" "available" {
  region = var.region
}

# Local vars
locals {
  labels = {
    env = "prod"
    app = "nightscout"
  }
  port = var.https ? 443 : 80
  zone = data.google_compute_zones.available.names[0]
}


# Cloud Storage bucket for deployments (replaces S3)
resource "google_storage_bucket" "deployment_bucket" {
  name     = "nightscout-deployments-${random_id.bucket_suffix.hex}"
  location = var.region
  labels   = local.labels

  uniform_bucket_level_access = true
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}


# Nightscout config in Secret Manager
module "secrets" {
  source = "./modules/secrets"
  region = var.region
  port   = local.port
  domain = var.domain
  labels = local.labels
}


# Service account for Compute Engine instance
module "service_account" {
  source     = "./modules/service_account"
  project_id = var.project_id
  labels     = local.labels
}


# VPC network & subnets
module "network" {
  source = "./modules/network"
  region = var.region
  ssh_source_ranges = var.my_ip != null ? ["${var.my_ip}/32"] : ["0.0.0.0/0"]
  labels = local.labels
}

# Compute Engine instance to run Nightscout
module "compute" {
  source = "./modules/compute"

  network_name        = module.network.network_name
  subnet_name         = module.network.subnet_name
  ssh_public_key_path = var.compute_ssh_public_key_path
  your_ip_address     = var.my_ip
  port                = local.port
  domain              = var.domain
  service_account_email = module.service_account.email
  labels              = local.labels
  project_id          = var.project_id
  region              = var.region
  zone                = local.zone
}
