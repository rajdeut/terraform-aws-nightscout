# Terraform for Nightscout running on AWS (free-tier)
[![License: MIT](https://img.shields.io/badge/License-MIT-brightgreen.svg)](./LICENSE)

### Description
This Terraform project has been developed to deploy a Nightscout instance on AWS using free-tier resources that best replicate the operating experience of Heroku.

While every effort has been made to ensure only free-tier resources are used, this may change as Amazon adjust their offering and we take no responsibility for the services deployed to your own AWS account. You can read more about what services are offered in their [free-tier here](https://aws.amazon.com/free/).


### Installation
Detailed instructions on how to use this project are located in this repository's [wiki](https://github.com/rajdeut/terraform-aws-nightscout/wiki/Setup-guide).

There is also a step-by-step walkthrough video available on [YouTube](https://youtu.be/cXdbYfG01jU), which follows the setup guide in the wiki.

The project is setup to access AWS credentials in its `config` and not system defaults such as `~/.aws/credentials`. If you're an experienced Terraform/AWS user you may wish to change this and can do so by modifying the `providers.tf` file as per [Terraform's instructions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).
If doing this I suggest forking & modifying this repo instead of cloning it.

### Terraform details
#### Inputs
- `display_units` [mmol|mgl] (default: mmol) - The blood glucose level of measurement to be used
- `ec2_ssh_public_key_path` (default: config/nightscout-ec2-key.pub) - Path to the public key to be installed on the Nightscout server
- `git_owner` (**required**) - Your GitHub username
- `git_repo` (default: cgm-remote-monitor) - The name of the GitHub Nightscout repository to connect
- `my_ip` (optional) - The IP address to whitelist for SSH access to the Nightscout server
- `port` (default: 80) - The webserver port Nightscout will operate on


#### Outputs
- `nightscout_url` - The IP address for the Nightscout instance that has been created