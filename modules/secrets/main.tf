# Setup secrets in Google Secret Manager
locals {
  # Load configuration from .env file if it exists
  env_file_exists = fileexists("${path.module}/../../config/nightscout.env")
  env_file_content = local.env_file_exists ? file("${path.module}/../../config/nightscout.env") : ""

  # Parse .env file format (VARIABLE="value" or VARIABLE=value)
  # Filter out comments and empty lines, then parse key=value pairs
  env_lines = local.env_file_exists ? [
    for line in split("\n", local.env_file_content) :
    trimspace(line)
    if length(trimspace(line)) > 0 && !startswith(trimspace(line), "#")
  ] : []

  # Convert to map: extract key and value from each line
  env_vars = {
    for line in local.env_lines :
    trimspace(split("=", line)[0]) => trimspace(replace(join("=", slice(split("=", line), 1, length(split("=", line)))), "\"", ""))
    if length(split("=", line)) >= 2
  }
}

# Create secrets from the nightscout config file
resource "google_secret_manager_secret" "config_secrets" {
  for_each  = local.env_vars
  secret_id = "nightscout-${lower(each.key)}"

  labels = var.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "config_secret_versions" {
  for_each    = google_secret_manager_secret.config_secrets
  secret      = each.value.id
  secret_data = local.env_vars[each.key]
}

# Cloud Run uses HTTPS by default, no need for port or SSL configuration