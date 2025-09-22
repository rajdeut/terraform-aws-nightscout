variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to access SSH (default allows all)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}