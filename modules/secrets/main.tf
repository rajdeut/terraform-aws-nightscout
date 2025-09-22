resource "oci_vault_vault" "nightscout_vault" {
  compartment_id   = var.compartment_id
  display_name     = "nightscout-vault"
  vault_type       = "DEFAULT"
  freeform_tags    = var.tags
}

resource "oci_kms_key" "nightscout_key" {
  compartment_id = var.compartment_id
  display_name   = "nightscout-key"
  key_shape {
    algorithm = "AES"
    length    = 32
  }
  management_endpoint = oci_vault_vault.nightscout_vault.management_endpoint
  freeform_tags       = var.tags
}

resource "oci_vault_secret" "nightscout_env" {
  compartment_id = var.compartment_id
  secret_name    = "nightscout-env"
  description    = "Nightscout environment variables"
  key_id         = oci_kms_key.nightscout_key.id
  vault_id       = oci_vault_vault.nightscout_vault.id

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.nightscout_env_content)
  }

  freeform_tags = var.tags
}