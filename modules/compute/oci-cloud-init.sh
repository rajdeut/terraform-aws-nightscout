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
# Install Docker
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
# Setup Nightscout configuration files
#######################################
setup_nightscout_config() {
  echo_header "Setup Nightscout configuration"

  # Create environment file
  cat <<'EOF' > /opt/nightscout/.env
${env_content}
EOF

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
  start_docker
  setup_nightscout_config
  setup_systemd_service

  echo_header "Nightscout installation completed successfully"
}

main "$@"