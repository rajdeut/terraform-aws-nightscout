#!/bin/bash

# Get latest vars from SSM
sudo aws ssm get-parameters-by-path --region ap-southeast-2 --path /nightscout --query 'Parameters[*].{Name:Name,Value:Value}' --with-decryption | jq -r '.[] | "\(.Name|split("/")|.[-1]|ascii_upcase)=\(.Value|@sh)"' > /srv/cgm-remote-monitor/.env

# Start the service
sudo systemctl restart nightscout.service
