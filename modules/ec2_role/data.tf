data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "ec2_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "read_ssm" {
  statement {
    actions   = ["ssm:GetParametersByPath"]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/nightscout"]
  }
}

data "aws_iam_policy_document" "codedeploy_s3" {
  statement {
    actions   = ["s3:Get*", "s3:List*"]
    resources = ["${var.codepipeline_bucket_arn}/*"]
  }
}
