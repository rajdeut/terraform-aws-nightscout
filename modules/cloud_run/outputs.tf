output "service_url" {
  description = "HTTPS URL of the Cloud Run service"
  value       = google_cloud_run_service.nightscout.status[0].url
}