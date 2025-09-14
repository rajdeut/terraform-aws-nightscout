variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = null
}

variable "your_ip_address" {
  description = "Your IP address for SSH access restriction"
  type        = string
  default     = null
}

variable "port" {
  description = "Port number for Nightscout (80 or 443)"
  type        = number
  default     = 80
}

variable "domain" {
  description = "Domain name for HTTPS/SSL"
  type        = string
  default     = null
}

variable "service_account_email" {
  description = "Email of the service account to attach to the instance"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}