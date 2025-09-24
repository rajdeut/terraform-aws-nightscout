# Parse environment variables from .env content
locals {
  # Split env content into lines and filter out comments/empty lines
  env_lines = [for line in split("\n", var.nightscout_env_content) :
  trimspace(line) if trimspace(line) != "" && !startswith(trimspace(line), "#")]

  # Parse key=value pairs from .env file
  parsed_env_vars = { for line in local.env_lines :
    split("=", line)[0] => join("=", slice(split("=", line), 1, length(split("=", line))))
    if length(split("=", line)) >= 2
  }

  # Default environment variables for Nightscout
  default_env_vars = {
    TRUST_PROXY       = "true"
    INSECURE_USE_HTTP = "true"
  }

  # Merge parsed vars with defaults (parsed vars take precedence)
  env_vars = merge(local.default_env_vars, local.parsed_env_vars)
}

# Create a KMS key for encrypting secrets
resource "oci_kms_vault" "nightscout_vault" {
  compartment_id = var.compartment_id
  display_name   = "nightscout-vault"
  vault_type     = "DEFAULT"

  freeform_tags = var.tags
}

resource "oci_kms_key" "nightscout_key" {
  compartment_id = var.compartment_id
  display_name   = "nightscout-encryption-key"

  key_shape {
    algorithm = "AES"
    length    = 32
  }

  management_endpoint = oci_kms_vault.nightscout_vault.management_endpoint

  freeform_tags = var.tags
}

# Create individual secrets for each environment variable
resource "oci_vault_secret" "nightscout_secrets" {
  for_each = local.env_vars

  compartment_id = var.compartment_id
  secret_name    = "nightscout-${lower(replace(each.key, "_", "-"))}"
  vault_id       = oci_kms_vault.nightscout_vault.id
  key_id         = oci_kms_key.nightscout_key.id

  secret_content {
    content_type = "BASE64"
    content      = base64encode(each.value)
  }

  freeform_tags = var.tags
}
