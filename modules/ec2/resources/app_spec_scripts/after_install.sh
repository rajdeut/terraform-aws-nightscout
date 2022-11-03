#!/bin/bash

# Setup env
export NODE_OPTIONS="--max-old-space-size=5120"

# Install node packages
cd /srv/cgm-remote-monitor/
npm install
npm run postinstall
npm install -y env-cmd

# Something weird need to copy compiled scripts elsewhere
sudo cp -R tmp/public /tmp/.

# Get ENV vars from SSM
touch .env
# escape values with @sh
#aws ssm get-parameters-by-path --region ap-southeast-2 --path /nightscout --query 'Parameters[*].{Name:Name,Value:Value}' --with-decryption | jq -r '.[] | "\(.Name|split("/")|.[-1]|ascii_upcase)=\(.Value|@sh)"' > .env
# wraps values in double quotes with no escaping
#aws ssm get-parameters-by-path --region ap-southeast-2 --path /nightscout --query 'Parameters[*].{Name:Name,Value:Value}' --with-decryption | jq -r '.[] | "\(.Name|split("/")|.[-1]|ascii_upcase)=\"\(.Value)\""' > .env