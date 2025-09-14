# Setup env vars in SSM
locals {
  params = jsondecode(fileexists("${path.module}/../../config/nightscout.config.json") ? file("${path.module}/../../config/nightscout.config.json") : "{}")
}

resource "aws_ssm_parameter" "config_params" {
  for_each  = { for idx, v in local.params : idx => v }
  name      = "/nightscout/${upper(each.value.name)}"
  type      = "String"
  value     = each.value.value
  tags      = var.tags
  overwrite = true
}

resource "aws_ssm_parameter" "port_param" {
  name      = "/nightscout/PORT"
  type      = "String"
  value     = var.port
  tags      = var.tags
  overwrite = true
}

resource "aws_ssm_parameter" "insecure_use_http_param" {
  name      = "/nightscout/INSECURE_USE_HTTP"
  type      = "String"
  value     = var.port == 80 ? "true" : "false"
  tags      = var.tags
  overwrite = true
}

# SSL vars
resource "aws_ssm_parameter" "ssl_key_param" {
  count     = var.port == 443 && var.domain != null ? 1 : 0
  name      = "/nightscout/SSL_KEY"
  type      = "String"
  value     = "/etc/letsencrypt/live/${lower(var.domain)}/privkey.pem"
  tags      = var.tags
  overwrite = true
}
resource "aws_ssm_parameter" "ssl_cert_param" {
  count     = var.port == 443 && var.domain != null ? 1 : 0
  name      = "/nightscout/SSL_CERT"
  type      = "String"
  value     = "/etc/letsencrypt/live/${lower(var.domain)}/fullchain.pem"
  tags      = var.tags
  overwrite = true
}
resource "aws_ssm_parameter" "ssl_ca_param" {
  count     = var.port == 443 && var.domain != null ? 1 : 0
  name      = "/nightscout/SSL_CA"
  type      = "String"
  value     = "/etc/letsencrypt/live/${lower(var.domain)}/chain.pem"
  tags      = var.tags
  overwrite = true
}
