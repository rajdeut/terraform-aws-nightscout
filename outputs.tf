output "nightscout_url" {
  value = format("%s://%s", local.port == 443 ? "https" : "http", var.domain != null ? var.domain : module.ec2.ec2_ip_address)
}
