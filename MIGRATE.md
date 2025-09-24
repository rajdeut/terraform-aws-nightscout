# Migrating to a new AWS account

## Create resources

If you're using a dirty install folder (ie. Terraform has been used before) then you need to delete the .tfstate, backup and lock files and then re-init Terraform. 

`terraform init`

Now you can build wih vars you want
`terraform apply --var "git_owner=rajdeut" --var "domain=ns.webstar.net.au" --var "my_ip=119.18.25.212" --var "https=true"`

## Copying config params

Install the util
`pip install aws-ssm-copy`

Copy the param store over
`aws-ssm-copy --source-profile nightscout --recursive / --profile nightscout-2024 --region ap-southeast-2 --overwrite`

## Connect github
Go through the connect & pipeline kick-off steps of the install wiki

## Update DNS
Repoint the domain to the new EC2 IP.

If you're updating the DNS here the SSL wont have generated during the install process.
SSH into the machine and then as `sudo su` run:
`certbot certonly -n --agree-tos --no-eff-email -a standalone -m webmaster@`