# Create service account for Nightscout Compute Engine instance
resource "google_service_account" "nightscout_service_account" {
  account_id   = "nightscout-compute"
  display_name = "Nightscout Compute Service Account"
  description  = "Service account for Nightscout Compute Engine instance with access to secrets"
}

# Grant necessary permissions to the service account
resource "google_project_iam_binding" "secret_manager_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:${google_service_account.nightscout_service_account.email}"
  ]
}

resource "google_project_iam_binding" "secret_manager_viewer" {
  project = var.project_id
  role    = "roles/secretmanager.viewer"

  members = [
    "serviceAccount:${google_service_account.nightscout_service_account.email}"
  ]
}

# Grant storage access for potential deployment artifacts
resource "google_project_iam_binding" "storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"

  members = [
    "serviceAccount:${google_service_account.nightscout_service_account.email}"
  ]
}

# Grant logging permissions for debugging
resource "google_project_iam_binding" "logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"

  members = [
    "serviceAccount:${google_service_account.nightscout_service_account.email}"
  ]
}

# Grant monitoring writer permissions
resource "google_project_iam_binding" "monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.nightscout_service_account.email}"
  ]
}