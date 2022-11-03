variable "port" {
  description = "Port to run webserver on"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "tags for all the resources, if any"
}
