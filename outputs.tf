output "nightscout_public_ip" {
  description = "Public IP address of the Nightscout server"
  value       = module.compute.public_ip
}

output "nightscout_url" {
  description = "URL to access your Nightscout application"
  value       = "http://${module.compute.public_ip}"
}

output "nightscout_url_https" {
  description = "URL to access your Nightscout application (after domain setup)"
  value       = "https://${var.domain}"
}

output "ssh_command" {
  description = "Command to SSH into the server"
  value       = module.compute.ssh_command
}
