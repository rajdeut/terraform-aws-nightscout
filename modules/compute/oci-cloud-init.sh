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

  # Create Caddyfile
  cat <<'EOF' > /opt/nightscout/Caddyfile
${caddyfile_content}
EOF

  # Create docker-compose.yml
  cat <<'EOF' > /opt/nightscout/docker-compose.yml
${compose_content}
EOF

  sudo mkdir -p /opt/nightscout/data
  sudo chown -R opc:opc /opt/nightscout
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
${systemd_content}
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
${rotate_script_content}
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