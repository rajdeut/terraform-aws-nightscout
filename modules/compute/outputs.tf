output "instance_name" {
  description = "Name of the compute instance"
  value       = google_compute_instance.nightscout_server.name
}

output "instance_id" {
  description = "ID of the compute instance"
  value       = google_compute_instance.nightscout_server.id
}

output "public_ip" {
  description = "Static public IP address of the instance"
  value       = google_compute_address.nightscout_static_ip.address
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = google_compute_instance.nightscout_server.network_interface[0].network_ip
}