variable "compartment_name" {
  description = "Name for the compartment"
  type        = string
  default     = "terraform-nightscout"
}

variable "compartment_description" {
  description = "Description for the compartment"
  type        = string
  default     = "Compartment for Nightscout deployment managed by Terraform"
}

variable "tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}
