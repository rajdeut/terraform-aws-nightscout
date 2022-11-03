# Codestar/Github connection
resource "aws_codestarconnections_connection" "github_connection" {
  name          = "nightscout__github_connection"
  provider_type = "GitHub"
  tags          = var.tags
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name               = "nightscout__codepipeline_role"
  tags               = var.tags
  description        = "Allow CodePipeline to read from S3 & manage deployments"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_role_policy.json
}
resource "aws_iam_policy" "codepipeline_access_policy" {
  name   = "nightscout__codepipeline_policy"
  policy = data.aws_iam_policy_document.codepipeline_access_policy.json
}
resource "aws_iam_policy_attachment" "_" {
  name       = "nightscout__codepipeline_iam_role-policy"
  policy_arn = aws_iam_policy.codepipeline_access_policy.arn
  roles      = [aws_iam_role.codepipeline_role.name]
}


# CodePipeline
resource "aws_codepipeline" "codepipeline_settings" {
  name     = "nightscout__pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github_connection.arn
        FullRepositoryId = "${var.git_owner}/${var.git_repo}"
        BranchName       = "master"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["source"]

      configuration = {
        ApplicationName     = var.codedeploy_app_name
        DeploymentGroupName = "nightscout__deployment_group"
      }
    }
  }
}
