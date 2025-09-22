# Enable required APIs
resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"
}

resource "google_project_service" "secret_manager_api" {
  service = "secretmanager.googleapis.com"
}

# We'll receive the secret names from the secrets module instead of querying

# Cloud Run v2 service with proper service-level scaling
resource "google_cloud_run_v2_service" "nightscout" {
  name     = "nightscout"
  location = var.region

  deletion_protection = false  # Allow terraform destroy

  # ✅ Service-level scaling (preferred) — keep 1 warm instance for AndroidAPS
  scaling {
    min_instance_count = 0  # Scale to zero for free tier compliance
    max_instance_count = 3
  }

  template {
    # Gen1 required for <1 vCPU + tiny memory free-tier strategy
    annotations = {
      "run.googleapis.com/execution-environment" = "gen1"
      # CPU only during requests (request-based billing)
      "run.googleapis.com/cpu-throttling" = "true"
      # Concurrency must be 1 when using <1 vCPU
      "autoscaling.knative.dev/maxScale" = "3"
    }

    service_account                  = var.service_account_email
    max_instance_request_concurrency = 1 # concurrency=1 required with <1 vCPU

    containers {
      image = "nightscout/cgm-remote-monitor:latest"

      ports { container_port = 8080 }

      startup_probe {
        http_get { path = "/" }
        initial_delay_seconds = 240
        timeout_seconds       = 10
        period_seconds        = 20
        failure_threshold     = 20
      }

      resources {
        limits = {
          cpu    = "1.0"    # Full CPU for fast startup and processing
          memory = "512Mi"  # Enough memory for Nightscout to start reliably
        }
        cpu_idle          = true # throttle CPU when idle (Gen1 request-based)
        startup_cpu_boost = false
      }

      dynamic "env" {
        for_each = var.secret_names
        content {
          name = upper(replace(replace(env.value, "nightscout-", ""), "-", "_"))
          value_source {
            secret_key_ref {
              secret  = env.value
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

resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_v2_service.nightscout.name
  location = google_cloud_run_v2_service.nightscout.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
