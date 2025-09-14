#!/bin/bash

# Automated deployment script that checks for git updates and redeploys if needed
# This script runs daily via cron

LOG_FILE="/var/log/nightscout-auto-deploy.log"
REPO_DIR="/srv/cgm-remote-monitor"
BRANCH="master"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Starting automated deployment check..."

# Change to repository directory
cd "$REPO_DIR" || {
    log_message "ERROR: Could not change to repository directory $REPO_DIR"
    exit 1
}

# Fetch latest changes from remote
log_message "Fetching latest changes from remote..."
git fetch origin

# Get current local commit hash
LOCAL_COMMIT=$(git rev-parse HEAD)
log_message "Current local commit: $LOCAL_COMMIT"

# Get remote commit hash
REMOTE_COMMIT=$(git rev-parse origin/$BRANCH)
log_message "Remote commit: $REMOTE_COMMIT"

# Check if update is needed
if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
    log_message "No updates available. Repository is up to date."
    exit 0
fi

log_message "New updates found! Starting deployment..."

# Stop the service
log_message "Stopping Nightscout service..."
systemctl stop nightscout.service

# Pull latest changes
log_message "Pulling latest changes..."
git reset --hard origin/$BRANCH
if [ $? -ne 0 ]; then
    log_message "ERROR: Failed to pull latest changes"
    systemctl start nightscout.service
    exit 1
fi

# Install/update dependencies
log_message "Installing dependencies..."
npm install --production
if [ $? -ne 0 ]; then
    log_message "ERROR: Failed to install dependencies"
    systemctl start nightscout.service
    exit 1
fi

# Sync secrets from Secret Manager
log_message "Syncing configuration from Secret Manager..."
/opt/nightscout/scripts/sync_secrets.sh

# Start the service
log_message "Starting Nightscout service..."
systemctl start nightscout.service

# Wait a moment and check service status
sleep 5
if systemctl is-active --quiet nightscout.service; then
    log_message "SUCCESS: Nightscout service is running after deployment"
    NEW_COMMIT=$(git rev-parse HEAD)
    log_message "Deployed commit: $NEW_COMMIT"
else
    log_message "ERROR: Nightscout service failed to start after deployment"
    systemctl status nightscout.service --no-pager -l >> "$LOG_FILE"
    exit 1
fi

log_message "Automated deployment completed successfully"