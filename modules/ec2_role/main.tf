resource "aws_iam_policy" "ssm_read_policy" {
  name   = "nightscout__read_ssm_policy"
  policy = data.aws_iam_policy_document.read_ssm.json
}
resource "aws_iam_policy" "s3_read_codedeploy_policy" {
  name   = "nightscout__read_codedeploy_buckets"
  policy = data.aws_iam_policy_document.codedeploy_s3.json
}

resource "aws_iam_role" "ec2_role" {
  name               = "nightscout__ec2_role"
  tags               = var.tags
  description        = "Allow an EC2 instance with this role to read nightscout vars in parameter store"
  assume_role_policy = data.aws_iam_policy_document.ec2_role_policy.json
}

resource "aws_iam_policy_attachment" "attach_ssm_role" {
  name       = "nightscout__ec2_iam_role-ssm_read_policy"
  policy_arn = aws_iam_policy.ssm_read_policy.arn
  roles      = [aws_iam_role.ec2_role.name]
}
resource "aws_iam_policy_attachment" "attach_s3_codedeploy_policy" {
  name       = "nightscout__ec2_iam_role-read-codedeploy-s3"
  policy_arn = aws_iam_policy.s3_read_codedeploy_policy.arn
  roles      = [aws_iam_role.ec2_role.name]
}

resource "aws_iam_role_policy_attachment" "attach_code_deploy_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "nightscout__ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}