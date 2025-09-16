# Enable required APIs
resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"
}

resource "google_project_service" "secret_manager_api" {
  service = "secretmanager.googleapis.com"
}

# We'll receive the secret names from the secrets module instead of querying

# Cloud Run v2 service with proper service-level scaling
resource "google_cloud_run_v2_service" "nightscout_v2" {
  name     = "nightscout"
  location = var.region

  template {
    scaling {
      min_instance_count = 1  # Keep 1 instance always running
      max_instance_count = 3  # Max 3 concurrent instances
    }

    service_account = var.service_account_email

    containers {
      image = "nightscout/cgm-remote-monitor:latest"

      ports {
        container_port = 8080
      }

      startup_probe {
        http_get {
          path = "/"
        }
        initial_delay_seconds = 240
        timeout_seconds = 10
        period_seconds = 20
        failure_threshold = 20
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "1Gi"
        }
        cpu_idle = true
        startup_cpu_boost = false
      }

      # Environment variables from secrets
      dynamic "env" {
        for_each = var.secret_names
        content {
          name = upper(replace(replace(env.value, "nightscout-", ""), "-", "_"))
          value_source {
            secret_key_ref {
              secret = env.value
              version = "latest"
            }
          }
        }
      }

      # Ensure Nightscout binds to all interfaces
      env {
        name  = "HOSTNAME"
        value = "0.0.0.0"
      }

      # Set Node.js to production mode
      env {
        name  = "NODE_ENV"
        value = "production"
      }
    }
  }

  depends_on = [google_project_service.cloud_run_api]
}

# Make the service publicly accessible
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_v2_service.nightscout_v2.name
  location = google_cloud_run_v2_service.nightscout_v2.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}