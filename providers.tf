provider "aws" {
  shared_credentials_files = ["${path.root}/config/aws-credentials"]
  shared_config_files      = ["${path.root}/config/aws-config"]
}
