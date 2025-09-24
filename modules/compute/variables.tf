variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}

variable "domain" {
  description = "Domain name for accessing Nightscout (e.g., nightscout.example.com)"
  type        = string
}
variable "subnet_id" {
  description = "The OCID of the subnet where the instance will be created"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "./config/nightscout_ssh.pub"
}

variable "vault_id" {
  description = "The OCID of the OCI Vault containing secrets"
  type        = string
}

variable "secret_ocids" {
  description = "Map of environment variable names to their secret OCIDs"
  type        = map(string)
  sensitive   = true
}

variable "env_vars" {
  description = "List of environment variable names"
  type        = list(string)
}

variable "tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}
