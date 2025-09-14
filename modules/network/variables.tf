variable "region" {
  description = "GCP region"
  type        = string
}

variable "ssh_source_ranges" {
  description = "IP ranges allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels for all the resources"
}