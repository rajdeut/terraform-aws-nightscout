variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels for all the resources"
}