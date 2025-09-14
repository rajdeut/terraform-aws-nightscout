output "secret_names" {
  description = "List of all secret names created"
  value = concat(
    [for secret in google_secret_manager_secret.config_secrets : secret.secret_id],
    [google_secret_manager_secret.port_secret.secret_id],
    [google_secret_manager_secret.insecure_use_http_secret.secret_id],
    var.port == 443 && var.domain != null ? [
      google_secret_manager_secret.ssl_key_secret[0].secret_id,
      google_secret_manager_secret.ssl_cert_secret[0].secret_id,
      google_secret_manager_secret.ssl_ca_secret[0].secret_id
    ] : []
  )
}