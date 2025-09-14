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

variable "tags" {
  type        = map(string)
  default     = {}
  description = "tags for all the resources, if any"
}
