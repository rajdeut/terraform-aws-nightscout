output "env_content" {
  description = "Base64 encoded Nightscout environment content"
  value       = local.encoded_env_content
  sensitive   = true
}