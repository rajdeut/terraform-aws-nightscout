output "compute_public_ip" {
  description = "Public IP address of the Nightscout server"
  value       = module.compute.public_ip
}

output "application_url" {
  description = "URL to access the Nightscout application"
  value       = var.domain != null && var.https ? "https://${var.domain}" : "http://${module.compute.public_ip}"
}

output "ssh_command" {
  description = "Command to SSH into the server"
  value       = "gcloud compute ssh nightscout-server --zone=${local.zone}"
}
