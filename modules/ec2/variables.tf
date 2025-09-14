variable "vpc_id" {
  type        = string
  description = "The VPC ID to place the EC2 instance"
}

variable "public_subnet_id" {
  type        = string
  description = "The Public Subnet to place the EC2 instance"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "AWS EC2 instance size to use"
}

variable "instance_profile_name" {
  type        = string
  description = "Instance profile to use for EC2 to assum IAM role"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Publick key to install on EC2"
}

variable "your_ip_address" {
  type        = string
  description = "Your IP address to access the EC2 via SSH"
  default     = null
}

variable "port" {
  type        = number
  description = "Port number to run web server on"
  default     = 80
}

variable "domain" {
  type        = string
  description = "Domain to run Nightscout on"
  default     = null
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "tags for all the resources, if any"
}
