variable "tags" {
  type        = map(string)
  default     = {}
  description = "tags for all the resources, if any"
}

variable "codepipeline_bucket_arn" {
  type = string
  description = "ARN of CodeDeploy bucket EC2 IAM role needs access to"
}
