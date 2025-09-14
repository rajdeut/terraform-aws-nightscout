#!/bin/bash

# Update package list and install base packages
apt-get update -y
apt-get install -y curl wget git jq unzip software-properties-common

# Install Google Cloud SDK for secret manager access
curl -sSL https://sdk.cloud.google.com | bash
source /root/.bashrc
export PATH=$PATH:/root/google-cloud-sdk/bin

# Install Node.js 18 (LTS)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install certbot for SSL certificates
apt-get install -y certbot

# Create tmp folder that mongo util needs
mkdir -p /tmp/public

# Clone nightscout repo
cd /srv
git clone https://github.com/nightscout/cgm-remote-monitor.git
cd cgm-remote-monitor

# Create a swap file because npm run postinstall requires memory
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Create nightscout config directory
mkdir -p /etc/nightscout

# Setup systemctl service for nightscout
cat > /etc/systemd/system/nightscout.service << 'EOL'
[Unit]
Description=Nightscout Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/srv/cgm-remote-monitor
EnvironmentFile=/etc/nightscout/environment
ExecStart=/usr/bin/node /srv/cgm-remote-monitor/lib/server/server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable nightscout.service

# Create scripts directory
mkdir -p /opt/nightscout/scripts

# Create secret manager sync script
cat > /opt/nightscout/scripts/sync_secrets.sh << 'EOL'
[[SYNC_SECRETS]]
EOL

# Create automated deployment script
cat > /opt/nightscout/scripts/auto_deploy.sh << 'EOL'
[[AUTO_DEPLOY]]
EOL

# Let's Encrypt SSL setup script (if domain provided)
[[LETSENCRYPT]]

# Make scripts executable
chmod +x /opt/nightscout/scripts/*.sh

# Initial secret sync
/opt/nightscout/scripts/sync_secrets.sh

# Setup cronjobs
crontab -l > /tmp/current_cron || true
echo "0 * * * * /opt/nightscout/scripts/sync_secrets.sh >/dev/null 2>&1" >> /tmp/current_cron
echo "0 2 * * * /opt/nightscout/scripts/auto_deploy.sh" >> /tmp/current_cron
crontab /tmp/current_cron
rm /tmp/current_cron

# Install node dependencies and start service
cd /srv/cgm-remote-monitor
npm install
systemctl start nightscout.service