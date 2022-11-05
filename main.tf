terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.38.0"
    }
  }
}

# Local vars
locals {
  tags = {
    env = "prod"
    app = "nightscout"
  }
}


# S3 Bucket for codedeploy/codepipeline
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket_prefix = "nightscout-codepipeline-"
  tags = var.tags
}
resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"
}


# Nightscout config in SSM
module "ssm" {
  source        = "./modules/ssm"
  port          = var.port
  tags          = local.tags
}


# IAM role & policy for EC2 to access SSM & S3
module "ec2_role" {
  source                  = "./modules/ec2_role"
  codepipeline_bucket_arn = aws_s3_bucket.codepipeline_bucket.arn
  tags                    = local.tags
}


# VPC, IG & Routing
module "vpc" {
  source = "./modules/vpc"
  tags   = local.tags
}

# EC2 instance to run Nightscout
module "ec2" {
  source = "./modules/ec2"

  vpc_id                = module.vpc.vpc_id
  public_subnet_id      = module.vpc.public_subnet_id
  ssh_public_key_path   = var.ec2_ssh_public_key_path
  your_ip_address       = var.my_ip
  instance_profile_name = module.ec2_role.instance_profile.name
  tags                  = local.tags
}


# CodeDeploy
module "codedeploy" {
  source = "./modules/codedeploy"
  tags   = local.tags
}

# CodePipeline to deploy from GitHub to EC2
module "codepipeline" {
  source              = "./modules/codepipeline"
  codedeploy_app_name = module.codedeploy.app_name
  git_owner           = var.git_owner
  git_repo            = var.git_repo
  artifact_bucket     = aws_s3_bucket.codepipeline_bucket
  tags                = local.tags
}
