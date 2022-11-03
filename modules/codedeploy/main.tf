resource "aws_codedeploy_app" "codedeploy_app" {
  name             = "nightscout__deploy_app"
  compute_platform = "Server"
  tags             = var.tags
}

resource "aws_iam_role" "codedeploy_role" {
  name               = "nightscout__codedeploy_role"
  tags               = var.tags
  description        = "Allow CodeDeploy to adopt role"
  assume_role_policy = data.aws_iam_policy_document.deployment_group_role_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_codedeploy_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_role.name
}

resource "aws_codedeploy_deployment_group" "codedeploy_group" {
  app_name              = aws_codedeploy_app.codedeploy_app.name
  deployment_group_name = "nightscout__deployment_group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "env"
      type  = "KEY_AND_VALUE"
      value = "prod"
    }

    ec2_tag_filter {
      key   = "app"
      type  = "KEY_AND_VALUE"
      value = "nightscout"
    }
  }


  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}