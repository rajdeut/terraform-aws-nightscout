# Construct the user_data script
locals {
  user_data_script = file("${path.module}/resources/user_data.sh")
  replacement_map = {
    CRON_SSM      = file("${path.module}/resources/cron_ssm.sh")
    LETSENCRYPT   = var.port == 443 && var.domain != null ? replace(file("${path.module}/resources/letsencrypt.sh"), "[[DOMAIN]]", var.domain) : ""
    AFTER_INSTALL = file("${path.module}/resources/app_spec_scripts/after_install.sh")
    APP_START     = file("${path.module}/resources/app_spec_scripts/app_start.sh")
    APP_STOP      = file("${path.module}/resources/app_spec_scripts/app_stop.sh")
  }
  user_data_script_final = replace(
    replace(
      replace(
        replace(
          replace(
            local.user_data_script, "[[CRON_SSM]]", local.replacement_map.CRON_SSM
          ),
          "[[LETSENCRYPT]]", local.replacement_map.LETSENCRYPT
        ),
        "[[APP_STOP]]", local.replacement_map.APP_STOP
      ),
      "[[APP_START]]", local.replacement_map.APP_START
    ),
    "[[AFTER_INSTALL]]", local.replacement_map.AFTER_INSTALL
  )
}

resource "aws_instance" "ec2_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.ec2_security_group.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ec2_key_pair.key_name
  iam_instance_profile        = var.instance_profile_name
  tags                        = merge(var.tags, { Name = "nightscout__ec2_instance" })
  user_data                   = local.user_data_script_final
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "nightscout__key_pair"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_security_group" "ec2_security_group" {
  name        = "nightscout__ec2_security_group"
  description = "Allow incoming HTTP/S & SSH traffic to Nightscout EC2 instance"
  vpc_id      = var.vpc_id
  tags        = var.tags

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.your_ip_address != null ? ["${var.your_ip_address}/32"] : []
  }
  ingress {
    description = "Web Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "MongoDB Atlas"
    from_port   = 27017
    protocol    = "tcp"
    to_port     = 27017
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
