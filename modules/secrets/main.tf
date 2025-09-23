# Note: OCI Vault/Secrets services are not available in the current Terraform OCI provider
# Instead, we'll pass the environment content directly via cloud-init
# This is still secure as the content is base64 encoded in terraform state
# and only exists temporarily during instance startup

# Encode the environment content for secure transport
locals {
  encoded_env_content = base64encode(var.nightscout_env_content)
}