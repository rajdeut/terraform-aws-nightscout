data "aws_iam_policy_document" "codepipeline_access_policy" {
  statement {
    actions = ["s3:GetObject", "s3:GetObjectVersion", "s3:GetBucketVersioning", "s3:PutObjectAcl", "s3:PutObject"]
    resources = [
      "${var.artifact_bucket.arn}",
      "${var.artifact_bucket.arn}/*"
    ]
  }
  statement {
    actions   = ["codestar-connections:UseConnection"]
    resources = ["${aws_codestarconnections_connection.github_connection.arn}"]
  }
  statement {
    actions   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
    resources = ["*"]
  }
  statement {
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "codepipeline_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

