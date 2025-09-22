output "nightscout_public_ip" {
  description = "Public IP address of the Nightscout server"
  value       = module.compute.public_ip
}

output "nightscout_url" {
  description = "URL to access your Nightscout application"
  value       = "http://${module.compute.public_ip}"
}

output "ssh_command" {
  description = "Command to SSH into the server"
  value       = module.compute.ssh_command
}

output "instance_id" {
  description = "OCID of the compute instance"
  value       = module.compute.instance_id
}

output "compartment_id" {
  description = "OCID of the created compartment"
  value       = module.compartment.compartment_id
}

output "compartment_name" {
  description = "Name of the created compartment"
  value       = module.compartment.compartment_name
}