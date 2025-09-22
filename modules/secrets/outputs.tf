output "secret_id" {
  description = "OCID of the Nightscout environment secret"
  value       = oci_vault_secret.nightscout_env.id
}

output "vault_id" {
  description = "OCID of the vault"
  value       = oci_vault_vault.nightscout_vault.id
}