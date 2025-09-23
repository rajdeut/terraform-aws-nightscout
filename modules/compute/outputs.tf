output "public_ip" {
  description = "Public IP address of the Nightscout server"
  value       = oci_core_instance.nightscout.public_ip
}

output "private_ip" {
  description = "Private IP address of the Nightscout server"
  value       = oci_core_instance.nightscout.private_ip
}

output "instance_id" {
  description = "OCID of the compute instance"
  value       = oci_core_instance.nightscout.id
}

output "ssh_command" {
  description = "Command to SSH into the server"
  value       = "ssh opc@${oci_core_instance.nightscout.public_ip} -i ${substr(var.ssh_public_key_path, 0, length(var.ssh_public_key_path) - 4)}"
}
