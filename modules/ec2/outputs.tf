output "ec2_ip_address" {
  value = "${aws_instance.ec2_instance.public_ip}"
}