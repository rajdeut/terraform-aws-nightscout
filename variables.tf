
variable "region" {
  description = "The OCI region where resources will be created"
  type        = string
  default     = "us-ashburn-1"
}

variable "domain" {
  description = "Domain name for accessing Nightscout (e.g., nightscout.example.com). Leave empty to use IP-only access."
  type        = string
  default     = ""
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file for instance access"
  type        = string
  default     = "./config/nightscout_ssh.pub"
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to access the instance via SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Application = "nightscout"
    ManagedBy   = "terraform"
  }
}
