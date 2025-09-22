variable "compartment_id" {
  description = "The OCID of the compartment"
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

variable "secret_id" {
  description = "OCID of the secret containing Nightscout environment variables"
  type        = string
}

variable "tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}