output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.nightscout_vcn.id
}

output "subnet_id" {
  description = "OCID of the public subnet"
  value       = oci_core_subnet.nightscout_subnet.id
}

output "security_list_id" {
  description = "OCID of the security list"
  value       = oci_core_security_list.nightscout_sl.id
}

output "internet_gateway_id" {
  description = "OCID of the internet gateway"
  value       = oci_core_internet_gateway.nightscout_ig.id
}