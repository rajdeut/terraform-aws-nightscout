output "email" {
  description = "Email address of the service account"
  value       = google_service_account.nightscout_service_account.email
}

output "name" {
  description = "Name of the service account"
  value       = google_service_account.nightscout_service_account.name
}

output "account_id" {
  description = "Account ID of the service account"
  value       = google_service_account.nightscout_service_account.account_id
}