variable "port" {
  default     = 80
  description = "Port to run webserver on"
}

variable "display_units" {
  description = "mg/dl or mmol/L"
  default     = "mmol"
  validation {
    condition = anytrue([
      var.display_units == "mmol",
      var.display_units == "mgl"
    ])
    error_message = "Must be a valid display units value. Either 'mg/dl' or 'mmol/L'."
  }
}

variable "ec2_ssh_public_key_path" {
  description = "Public key to install on EC2"  
  default = "config/nightscout-ec2-key.pub"
}

variable "my_ip" {
  description = "Your IP address to access the EC2 via SSH"
  default = null
}

variable "git_repo" {
  description = "The name of your Nightscout repository on GitHub, eg 'cgm-remote-monitor'"
  default = "cgm-remote-monitor"
}

variable "git_owner" {
  description = "Your GitHub username"
}

variable "tags" {
  type = map(string)
  default = {
    env = "prod"
    app  = "nightscout"
  }
  description = "tags for all the resources, if any"
}
