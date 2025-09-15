output "application_url" {
  description = "HTTPS URL to access your Nightscout application"
  value       = module.cloud_run.service_url
}
