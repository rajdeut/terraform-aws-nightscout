variable "region" {
  description = "GCP region for secret replication"
  type        = string
}

variable "port" {
  default     = 80
  type        = number
  description = "Port to run webserver on"
}

variable "domain" {
  default     = null
  type        = string
  description = "The domain name to run Nightscout"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels for all the resources"
}