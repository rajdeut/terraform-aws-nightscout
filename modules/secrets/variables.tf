variable "region" {
  description = "GCP region for secret replication"
  type        = string
}


variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels for all the resources"
}