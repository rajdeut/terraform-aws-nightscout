variable "codedeploy_app_name" {
  type        = string
  description = "The name of the CodeDeploy App"

}

variable "git_repo" {
  description = "The name of your Nightscout repository on GitHub, eg 'cgm-remote-monitor'"
}

variable "git_owner" {
  description = "Your GitHub username"
}

variable "artifact_bucket" {
  type        = any
  description = "Bucket to store artefact that pipeline deploys"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "tags for all the resources, if any"
}
