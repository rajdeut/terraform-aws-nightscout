# Enable required APIs
resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"
}

resource "google_project_service" "secret_manager_api" {
  service = "secretmanager.googleapis.com"
}

# We'll receive the secret names from the secrets module instead of querying

# Cloud Run service for Nightscout
resource "google_cloud_run_service" "nightscout" {
  name     = "nightscout"
  location = var.region

  template {
    metadata {
      labels = var.labels
      annotations = {
        # Free tier limits: Stay within 2 million requests/month
        "autoscaling.knative.dev/maxScale" = "3"    # Max 3 concurrent instances
        "autoscaling.knative.dev/minScale" = "0"    # Scale to zero when idle
        "run.googleapis.com/execution-environment" = "gen2"
        "run.googleapis.com/cpu-throttling" = "true"  # CPU throttling to save costs
      }
    }

    spec {
      service_account_name = var.service_account_email

      containers {
        image = "nightscout/cgm-remote-monitor:latest"

        ports {
          container_port = 8080
        }

        # Add startup probe configuration - use /api/v1/status for health check
        startup_probe {
          http_get {
            path = "/api/v1/status"
          }
          initial_delay_seconds = 180
          timeout_seconds = 10
          period_seconds = 15
          failure_threshold = 15
        }

        # Add liveness probe to keep service healthy
        liveness_probe {
          http_get {
            path = "/api/v1/status"
          }
          initial_delay_seconds = 300
          timeout_seconds = 5
          period_seconds = 30
          failure_threshold = 3
        }

        resources {
          limits = {
            # Free tier: 1 vCPU and 1GiB memory per instance
            cpu    = "1000m"    # 1 vCPU (free tier limit)
            memory = "1Gi"      # 1GiB memory (free tier limit)
          }
          requests = {
            cpu    = "100m"     # Minimum CPU to keep costs low
            memory = "128Mi"    # Minimum memory to keep costs low
          }
        }

        # Environment variables from secrets
        dynamic "env" {
          for_each = var.secret_names
          content {
            name = upper(replace(replace(env.value, "nightscout-", ""), "-", "_"))
            value_from {
              secret_key_ref {
                name = env.value
                key  = "latest"
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
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.cloud_run_api]
}

# Make the service publicly accessible
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.nightscout.name
  location = google_cloud_run_service.nightscout.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}