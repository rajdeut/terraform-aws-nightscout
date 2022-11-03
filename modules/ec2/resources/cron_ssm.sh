#!/bin/bash

# Get the region
export AWS_REGION=`curl -s http://169.254.169.254/latest/meta-data/placement/region`

# Put vars into tmp file
sudo aws ssm get-parameters-by-path --region $AWS_REGION --path /nightscout --query 'Parameters[*].{Name:Name,Value:Value}' --with-decryption | jq -r '.[] | "\(.Name|split("/")|.[-1]|ascii_upcase)=\"\(.Value)\""' > /tmp/nightscout_env

if ! cmp /tmp/nightscout_env /srv/cgm-remote-monitor/.env --silent
then
    sudo cp /tmp/nightscout_env /srv/cgm-remote-monitor/.env
    sudo systemctl restart nightscout.service 
fi

# Delete tmp file
sudo rm /tmp/nightscout_env