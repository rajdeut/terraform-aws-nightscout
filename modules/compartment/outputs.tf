output "compartment_id" {
  description = "OCID of the created compartment"
  value       = oci_identity_compartment.nightscout.id
}

output "compartment_name" {
  description = "Name of the created compartment"
  value       = oci_identity_compartment.nightscout.name
}

output "tenancy_id" {
  description = "OCID of the tenancy"
  value       = data.oci_identity_tenancy.current.id
}