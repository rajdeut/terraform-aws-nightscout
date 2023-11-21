#!/bin/bash
sudo yum update -y

# Create tmp folder that mongo util needs
mkdir /tmp/public

# Package installs
sudo yum install git jq ruby wget -y

# Node Install
sudo yum install https://rpm.nodesource.com/pub_16.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y
sudo yum install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1

# Code Agent install
cd /home/ec2-user
export AWS_REGION=`curl -s http://169.254.169.254/latest/meta-data/placement/region`
wget https://aws-codedeploy-$AWS_REGION.s3.$AWS_REGION.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto

# Clone nightscout repo (do this as codepipeline fails until connection authenticated)
cd /srv
sudo git clone https://github.com/nightscout/cgm-remote-monitor.git
cd cgm-remote-monitor

# Create a swap file because npm run posinstall is hungry
#export NODE_OPTIONS="--max-old-space-size=5120"
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Setup systemctl service
sudo cat > /etc/systemd/system/nightscout.service << EOL
[Unit]
Description=Nightscout Service
After=network.target
[Service]
Type=simple
WorkingDirectory=/srv/cgm-remote-monitor
ExecStart=/srv/cgm-remote-monitor/node_modules/.bin/env-cmd node /srv/cgm-remote-monitor/lib/server/server.js
[Install]
WantedBy=multi-user.target
EOL
sudo systemctl daemon-reload
sudo systemctl enable nightscout.service

# Setup CodeDeploy / appspec scripts
sudo mkdir /opt/codedeploy-agent/scripts
sudo cat > /opt/codedeploy-agent/scripts/after_install.sh << EOL
[[AFTER_INSTALL]]
EOL
sudo cat > /opt/codedeploy-agent/scripts/app_start.sh << EOL
[[APP_START]]
EOL
sudo cat > /opt/codedeploy-agent/scripts/app_stop.sh << EOL
[[APP_STOP]]
EOL

# Create cronjob
sudo cat > /opt/codedeploy-agent/scripts/cron_ssm.sh << EOL
[[CRON_SSM]]
EOL

# Make scripts executable
sudo chmod +x /opt/codedeploy-agent/scripts/*.sh

# Create cronjob that gets env vars from SSM every 10 minutes & restarts if changes
# Removed, only get 20,000 calls to AWS Key Management Service per month & prev SSM was storing as SecureString.
# I think we can revert this after updating SSM.
crontab -l ; echo "*/10 * * * * sudo /opt/codedeploy-agent/scripts/cron_ssm.sh >/dev/null 2>&1" | crontab -
