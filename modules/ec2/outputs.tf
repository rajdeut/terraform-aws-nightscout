output "ec2_ip_address" {
  value = "${aws_instance.ec2_instance.public_ip}"
}

# Used for debuging
#output "ec2_user_data" {
#  value = local.user_data_script_final
#}
