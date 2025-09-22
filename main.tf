terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Local vars
locals {
  labels = {
    env = "prod"
    app = "nightscout"
  }
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
  labels = local.labels
}


# Service account for Cloud Run service
module "service_account" {
  source     = "./modules/service_account"
  project_id = var.project_id
  labels     = local.labels
}

# Cloud Run service to run Nightscout
module "cloud_run" {
  source                = "./modules/cloud_run"
  project_id            = var.project_id
  region                = var.region
  service_account_email = module.service_account.email
  secret_names          = module.secrets.secret_names
  labels                = local.labels

  depends_on = [module.secrets]
}
