output "secret_names" {
  description = "List of all secret names created from nightscout.env"
  value = [for secret in google_secret_manager_secret.config_secrets : secret.secret_id]
}