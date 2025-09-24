#!/bin/bash
#
# cloud-init script for Nightscout on Oracle Cloud Infrastructure
#

PGM=$(basename $0)

#######################################
# Print header
#######################################
echo_header() {
  echo "+++ $PGM: $@"
}

#######################################
# Create Nightscout directory
#######################################
setup_nightscout_directory() {
  echo_header "Setup Nightscout directory"

  sudo mkdir -p /opt/nightscout
  sudo chown opc:opc /opt/nightscout
}

#######################################
# Setup Swapfile
#######################################
setup_swapfile() {
  sudo fallocate -l 4G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
  sudo swapon -a
}

#######################################
# Install Docker and Docker Compose
#######################################
install_docker() {
  echo_header "Install Docker"

  sudo dnf makecache --refresh
  sudo yum install -y yum-utils device-mapper-persistent-data lvm2

  echo_header "Install docker repo"
  sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

  echo_header "Install docker-ce"
  sudo yum install -y docker-ce docker-ce-cli containerd.io

  echo_header "Add users to docker group"
  sudo usermod -aG docker opc
}

#######################################
# Install OCI CLI
#######################################
install_oci_cli() {
  echo_header "Install OCI CLI"

  # Install Python, pip, and jq
  sudo yum install -y python3 python3-pip jq

  # Install OCI CLI
  bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults

  # Add to PATH for all users
  echo 'export PATH=$PATH:/home/opc/bin' | sudo tee -a /etc/profile
}


#######################################
# Setup Nightscout configuration files
#######################################
setup_nightscout_config() {
  echo_header "Setup Nightscout configuration"

  # Note: .env file will be created by the rotation script during setup_secret_rotation

  # Create Caddyfile with automatic HTTPS
  cat <<'EOF' > /opt/nightscout/Caddyfile
# HTTP-only fallback for raw IP access
http://:80 {
    reverse_proxy nightscout:1337
}

# Your domain with automatic HTTPS
${domain} {
    encode gzip
    reverse_proxy nightscout:1337
}
EOF

  # Create docker-compose.yml
  cat <<'EOF' > /opt/nightscout/docker-compose.yml
services:
  caddy:
    image: caddy:2-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    restart: unless-stopped
    depends_on:
      - nightscout

  nightscout:
    image: nightscout/cgm-remote-monitor:latest
    environment:
      - PORT=1337
      - TRUST_PROXY=true
      - INSECURE_USE_HTTP=true
    env_file:
      - .env
    restart: unless-stopped
    volumes:
      - ./data:/var/opt/nightscout

volumes:
  caddy_data:
  caddy_config:
  nightscout_data:
EOF

  sudo mkdir -p /opt/nightscout/data
  sudo chown -R opc:opc /opt/nightscout
  sudo chmod 600 /opt/nightscout/.env
}

#######################################
# Enable and start Docker
#######################################
start_docker() {
  echo_header "Start Docker"
  sudo systemctl enable docker
  sudo systemctl start docker
}

#######################################
# Setup systemd service for Nightscout
#######################################
setup_systemd_service() {
  echo_header "Setup systemd service"

  cat <<'EOF' | sudo tee /etc/systemd/system/nightscout.service
[Unit]
Description=Nightscout Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/nightscout
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable nightscout.service
  sudo systemctl start nightscout.service
}

#######################################
# Setup automatic secret rotation
#######################################
setup_secret_rotation() {
  echo_header "Setup automatic secret rotation"

  # Create secret rotation script
  cat <<'SCRIPT' > /opt/nightscout/rotate-secrets.sh
#!/bin/bash

# Secret rotation script for Nightscout
LOG_FILE="/var/log/nightscout-secret-rotation.log"

log_message() {
  echo "$(date): $1" | sudo tee -a "$LOG_FILE"
}

# Parse JSON variables from template (same as during initial setup)
SECRET_OCIDS='${secret_ocids}'
ENV_VARS='${env_vars}'

# Export path for OCI CLI
export PATH=$PATH:/home/opc/bin

# Create temporary env file
TEMP_ENV="/tmp/.env.new"
echo "# Nightscout environment variables" > "$TEMP_ENV"
echo "# Updated on $(date)" >> "$TEMP_ENV"
echo "" >> "$TEMP_ENV"

# Fetch each secret
ALL_SECRETS_FETCHED=true
for var in $(echo "$ENV_VARS" | jq -r '.[]'); do
  secret_ocid=$(echo "$SECRET_OCIDS" | jq -r ".[\"$var\"]")

  if [[ "$secret_ocid" != "null" && -n "$secret_ocid" ]]; then
    secret_value=$(/home/opc/bin/oci secrets secret-bundle get --secret-id "$secret_ocid" --auth instance_principal --query 'data."secret-bundle-content".content' --raw-output 2>/dev/null | base64 -d 2>/dev/null)

    if [[ $? -eq 0 && -n "$secret_value" ]]; then
      echo "$var=$secret_value" >> "$TEMP_ENV"
    else
      log_message "Warning: Failed to fetch secret for $var"
      ALL_SECRETS_FETCHED=false
    fi
  else
    log_message "Warning: No secret OCID found for $var"
    ALL_SECRETS_FETCHED=false
  fi
done

# Only update if all secrets were fetched successfully
if [[ "$ALL_SECRETS_FETCHED" == "true" ]]; then
  # Compare with existing file
  if ! cmp -s "$TEMP_ENV" "/opt/nightscout/.env"; then
    log_message "Secrets changed, updating configuration and restarting services"

    # Backup old env file
    cp /opt/nightscout/.env /opt/nightscout/.env.backup

    # Update env file
    mv "$TEMP_ENV" /opt/nightscout/.env
    chmod 600 /opt/nightscout/.env
    chown opc:opc /opt/nightscout/.env

    # Restart Nightscout service
    cd /opt/nightscout && sudo docker compose restart nightscout

    log_message "Services restarted with updated secrets"
  else
    log_message "No changes detected in secrets"
    rm -f "$TEMP_ENV"
  fi
else
  log_message "Some secrets failed to fetch, keeping existing configuration"
  rm -f "$TEMP_ENV"
fi
SCRIPT

  chmod +x /opt/nightscout/rotate-secrets.sh
  chown opc:opc /opt/nightscout/rotate-secrets.sh

  # Create cron job for secret rotation (every 10 minutes)
  echo "*/10 * * * * /opt/nightscout/rotate-secrets.sh" | crontab -u opc -

  # Run the script once initially to create the .env file
  echo_header "Running initial secret fetch"
  /opt/nightscout/rotate-secrets.sh

  echo_header "Secret rotation setup completed"
}

#######################################
# Main
#######################################
main() {
  echo_header "Starting Nightscout installation"

  # MOTD
  sudo tee /etc/motd > /dev/null << 'EOF'

=====================================
Nightscout Server - Oracle Cloud
=====================================

Services:
  - Nightscout: Running on port 1337 (internal)
  - Caddy: HTTP proxy on ports 80/443

Management:
  sudo systemctl status nightscout
  cd /opt/nightscout && sudo docker compose logs -f

Configuration:
  /opt/nightscout/.env       (environment variables)
  /opt/nightscout/Caddyfile  (SSL proxy config)

=====================================
EOF

  setup_nightscout_directory
  setup_swapfile
  install_docker
  install_oci_cli
  start_docker
  setup_nightscout_config
  setup_systemd_service
  setup_secret_rotation

  echo_header "Nightscout installation completed successfully"
}

main "$@"