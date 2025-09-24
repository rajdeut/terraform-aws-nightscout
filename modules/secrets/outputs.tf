output "vault_id" {
  description = "The OCID of the OCI Vault"
  value       = oci_kms_vault.nightscout_vault.id
}

output "secret_ocids" {
  description = "Map of environment variable names to their secret OCIDs"
  value       = { for k, v in oci_vault_secret.nightscout_secrets : k => v.id }
  sensitive   = true
}

output "env_vars" {
  description = "List of environment variable names"
  value       = keys(local.env_vars)
}