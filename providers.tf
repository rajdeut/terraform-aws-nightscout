provider "google" {
  credentials = fileexists("${path.root}/config/gcp-credentials.json") ? file("${path.root}/config/gcp-credentials.json") : null
  project     = var.project_id
  region      = var.region
}
