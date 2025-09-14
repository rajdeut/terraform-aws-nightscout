variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}


variable "domain" {
  default     = null
  description = "Domain name Nightscout will run on"
}

variable "https" {
  default     = false
  description = "HTTPS enabled. Requires SSL installed to enable correctly"
}

variable "compute_ssh_public_key_path" {
  description = "Public key to install on Compute Engine instance"
  default     = "config/nightscout-compute-key.pub"
}

variable "my_ip" {
  description = "Your IP address to access the Compute Engine instance via SSH"
  default     = null
}

variable "labels" {
  type = map(string)
  default = {
    env = "prod"
    app = "nightscout"
  }
  description = "Labels for all the resources"
}
