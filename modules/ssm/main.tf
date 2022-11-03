# Setup env vars in SSM
locals {
  params = jsondecode(file("${path.module}/../../config/nightscout.config.json"))
}

resource "aws_ssm_parameter" "config_params" {
  for_each = { for idx, v in local.params : idx => v }
  name     = "/nightscout/${upper(each.value.name)}"
  type     = "String"
  value    = each.value.value
  tags     = var.tags
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
  value     = "true"
  tags      = var.tags
  overwrite = true
}
