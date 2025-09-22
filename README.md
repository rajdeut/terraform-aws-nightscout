# Terraform for Nightscout on Oracle Cloud Infrastructure (Always Free)
[![License: MIT](https://img.shields.io/badge/License-MIT-brightgreen.svg)](./LICENSE)

## Description
This Terraform project deploys a Nightscout instance on Oracle Cloud Infrastructure (OCI) using Always Free tier resources. The infrastructure provides a reliable, cost-effective hosting solution while maintaining the full functionality of the Nightscout continuous glucose monitoring application.

The deployment uses OCI's Always Free tier which includes:
- VM.Standard.E2.1.Micro compute instance (1/8 OCPU, 1 GB memory) - Always Free
- Block Volume storage up to 200 GB total - Always Free
- 10 TB of outbound data transfer per month - Always Free

## Prerequisites

### 1. Oracle Cloud Infrastructure Setup
1. **Create an OCI account**:
   - Sign up at [cloud.oracle.com](https://cloud.oracle.com)
   - Complete identity verification (may require credit card but Always Free resources remain free)

2. **Set up OCI CLI and authentication**:
   - Install [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
   - Run `oci setup config` to create API keys and config file
   - Note your tenancy OCID, user OCID, and region (compartment will be created automatically)

3. **Create SSH key pair**:
   ```bash
   ssh-keygen -t rsa -b 2048 -f config/nightscout_ssh
   ```

### 2. Terraform Installation
- Install [Terraform](https://www.terraform.io/downloads.html) (version 1.0+)

### 3. Configuration Files
- Copy `config/nightscout.env.example` to `config/nightscout.env` and update with your Nightscout settings
- **Optional**: Copy `terraform.tfvars.example` to `terraform.tfvars` for custom deployment settings

## Installation

1. **Clone this repository**
   ```bash
   git clone <repository-url>
   cd terraform--nightscout-aws
   ```

2. **Configure your Nightscout settings**:
   ```bash
   cp config/nightscout.env.example config/nightscout.env
   # Edit config/nightscout.env with your database URI, API secret, etc.
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Review the planned infrastructure**:
   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure**:
   ```bash
   terraform apply
   ```

   **Alternative**: Use terraform.tfvars for customization:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your preferences
   terraform apply
   ```

   *Note: This may take 5-10 minutes to complete as the instance boots and installs Docker/Caddy/Nightscout*

## Architecture Overview

### Infrastructure Components
- **Compartment**: Dedicated "terraform-nightscout" compartment for resource isolation
- **VCN (Virtual Cloud Network)**: Isolated network environment
- **Public Subnet**: For the Nightscout instance with internet access
- **Security Lists**: Firewall rules allowing HTTP (80), HTTPS (443), and SSH (22)
- **Compute Instance**: VM.Standard.E2.1.Micro (Always Free eligible)
- **Public IP**: Static IP address for accessing Nightscout
- **OCI Vault**: Secure storage for Nightscout environment variables
- **IAM Policies**: Dynamic group and policies for secure secrets access

### Software Stack
- **Oracle Linux 8**: Base operating system
- **Docker**: Container runtime for Nightscout
- **Caddy**: Web server and reverse proxy for SSL termination
- **Nightscout**: CGM monitoring application
- **OCI Vault**: Secure secrets management for environment variables

### Automatic Setup
The cloud-init script automatically:
1. Installs Docker, Docker Compose, and OCI CLI
2. Fetches Nightscout configuration securely from OCI Vault
3. Sets up automatic secret rotation (every 10 minutes)
4. Sets up Caddy for HTTP/HTTPS routing
5. Starts all services and enables auto-restart
6. Creates systemd service for container management

## Terraform Configuration

### Optional Variables
- `region` (default: us-ashburn-1) - OCI region for deployment
- `ssh_public_key_path` (default: ./config/nightscout_ssh.pub) - Path to SSH public key
- `ssh_allowed_cidr` (default: 0.0.0.0/0) - CIDR block for SSH access

### Outputs
- `nightscout_url` - HTTP URL to access your Nightscout application
- `nightscout_public_ip` - Public IP address of the server
- `ssh_command` - Command to SSH into the server
- `compartment_id` - OCID of the created compartment
- `compartment_name` - Name of the created compartment (terraform-nightscout)

## Post-Deployment

After deployment, you can:

1. **Access your Nightscout**: Use the `nightscout_url` output
   - Initially available via HTTP
   - HTTPS will be available if you configure a domain (see below)

2. **Use your own domain** (optional):
   - **Point your domain**: Create an A record pointing to the public IP:
     ```
     A record: nightscout.yourdomain.com → <public-ip-address>
     ```
   - **Update Caddyfile**: SSH into the server and edit `/opt/nightscout/Caddyfile`:
     ```
     nightscout.yourdomain.com {
         reverse_proxy nightscout:1337
     }
     ```
   - **Restart services**:
     ```bash
     cd /opt/nightscout && docker-compose restart caddy
     ```
   - **Automatic HTTPS**: Caddy will automatically obtain Let's Encrypt SSL certificates

3. **Monitor the service**:
   - **SSH into server**: Use the `ssh_command` output
   - **Check service status**: `sudo systemctl status nightscout`
   - **View logs**: `cd /opt/nightscout && docker-compose logs -f`
   - **Restart services**: `cd /opt/nightscout && docker-compose restart`

4. **Update configurations**:
   - **Recommended**: Update the secret in OCI Vault via the console or CLI
   - Nightscout will automatically pick up changes within 10 minutes
   - **Alternative**: Edit `/opt/nightscout/.env` directly (manual restart required)

## Always Free Tier Benefits

Oracle Cloud's Always Free tier provides:
- **Always-on compute**: VM.Standard.E2.1.Micro instance runs 24/7 at no cost
- **Generous bandwidth**: 10 TB outbound data transfer per month
- **Persistent storage**: Up to 200 GB block storage
- **No time limits**: Resources remain free indefinitely (not just trial period)
- **Multiple instances**: Can run up to 4 Always Free compute instances

## Cost Optimization

This deployment is designed to stay within Always Free limits:
- Uses the smallest available compute shape (VM.Standard.E2.1.Micro)
- Minimal storage requirements (OS + Docker images ~10-15 GB)
- Efficient resource usage with Docker containers
- **Expected monthly cost: $0** 🎉

## Management Commands

**Service Management:**
```bash
# Check service status
sudo systemctl status nightscout

# View application logs
cd /opt/nightscout && docker-compose logs -f

# Restart services
cd /opt/nightscout && docker-compose restart

# Update Nightscout image
cd /opt/nightscout && docker-compose pull && docker-compose up -d

# Check secret rotation logs
tail -f /var/log/nightscout-secret-rotation.log

# Manually trigger secret rotation
sudo /opt/nightscout/rotate-secrets.sh
```

**Backup Configuration:**
```bash
# Backup your configuration
scp oracle@<public-ip>:/opt/nightscout/.env ./nightscout.env.backup

# Backup Docker compose setup
scp oracle@<public-ip>:/opt/nightscout/docker-compose.yml ./docker-compose.yml.backup
```

## Troubleshooting

**If Nightscout isn't starting:**
1. SSH into the server: `ssh oracle@<public-ip>`
2. Check logs: `cd /opt/nightscout && docker-compose logs nightscout`
3. Verify configuration: `cat /opt/nightscout/.env`
4. Restart services: `docker-compose restart`

**If you can't access the web interface:**
1. Check if services are running: `docker-compose ps`
2. Verify ports are open: `sudo firewall-cmd --list-all` (if firewall is enabled)
3. Check security list allows HTTP/HTTPS traffic in OCI console

**For domain/SSL issues:**
1. Verify DNS points to the correct IP: `nslookup yourdomain.com`
2. Check Caddy logs: `docker-compose logs caddy`
3. Ensure port 443 is accessible from the internet