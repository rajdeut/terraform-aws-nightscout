variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "labels" {
  type = map(string)
  default = {
    env = "prod"
    app = "nightscout"
  }
  description = "Labels for all the resources"
}
