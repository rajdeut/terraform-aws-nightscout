output "service_url" {
  description = "HTTPS URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.nightscout_v2.uri
}