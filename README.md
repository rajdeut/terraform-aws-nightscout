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
   - Note your Oracle Cloud Tenancy OCID, User OCID, and region will be required. (A compartment will be created automatically)

3. **Create SSH key pair**:

   ```bash
   ssh-keygen -t rsa -b 2048 -f config/nightscout_ssh
   ```

### 2. Terraform Installation

- Install [Terraform](https://developer.hashicorp.com/terraform/install) (version 1.0+)

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

3. **Configure your Terraform deployment**:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your region and other preferences 
   ```

4. **Initialize Terraform**:

   ```bash
   terraform init
   ```

5. **Review the planned infrastructure**:

   ```bash
   terraform plan
   ```

6. **Deploy the infrastructure**:

   ```bash
   terraform apply
   ```

   *Note: This may take 10-15 minutes to complete as the instance boots and installs Docker/Caddy/Nightscout*

## Architecture Overview

### Infrastructure Components

- **Compartment**: Dedicated "terraform-nightscout" compartment for resource isolation
- **VCN (Virtual Cloud Network)**: Isolated network environment with 10.0.0.0/16 CIDR
- **Public Subnet**: 10.0.1.0/24 subnet for the Nightscout instance with internet access
- **Security Lists**: Firewall rules allowing HTTP (80), HTTPS (443), and SSH (22)
- **Compute Instance**: VM.Standard.E2.1.Micro (Always Free eligible, 1/8 OCPU, 1GB RAM)
- **Reserved Public IP**: Static IP address that persists across instance recreation
- **OCI Vault with KMS**: Secure encrypted storage for all Nightscout environment variables
- **IAM Policies**: Dynamic group and policies for secure vault access via instance principal
- **Auto-scaling**: 4GB swap file for memory optimization

### Software Stack

- **Oracle Linux 8**: Base operating system with cloud-init automation
- **Docker & Docker Compose**: Container runtime and orchestration for Nightscout
- **Caddy**: HTTP/HTTPS reverse proxy with automatic Let's Encrypt SSL certificates
- **Nightscout**: Official CGM monitoring application (latest Docker image)
- **OCI CLI**: For secure vault communication via instance principal authentication
- **Systemd**: Service management for automatic container startup and restart

### Automatic Setup

The cloud-init script automatically:

1. **System Setup**: Installs Docker, Docker Compose, OCI CLI, and required dependencies
2. **Memory Optimization**: Creates 8GB swap file for better performance
3. **Security Configuration**: Sets up dynamic group IAM policies for vault access
4. **Secret Management**: Fetches all environment variables securely from encrypted OCI Vault
5. **Service Deployment**: Creates and starts systemd service for container management
6. **Auto-Rotation**: Sets up cron job for secret rotation every 15 minutes
7. **SSL/HTTPS**: Configures Caddy for automatic Let's Encrypt certificate management
8. **Monitoring**: Sets up comprehensive logging and error handling

## Terraform Configuration

### Optional Variables

- `region` (default: us-ashburn-1) - OCI region for deployment
- `ssh_public_key_path` (default: ./config/nightscout_ssh.pub) - Path to SSH public key
- `ssh_allowed_cidr` (default: 0.0.0.0/0) - CIDR block for SSH access
- `tags` - Map of freeform tags to apply to all resources
- `domain` - Domain name for your Nightscout site (e.g., nightscout.example.com)

### Outputs

- `nightscout_public_ip` - Reserved public IP address of the Nightscout server
- `nightscout_url` - IP based URL when a domain is not registered
- `nightscout_url_https` - Domain based secure URL
- `ssh_command` - Ready-to-use SSH command for server access

## Post-Deployment

After deployment, you can:

1. **Access your Nightscout**: Use the `nightscout_url` output
   - Initially available via HTTP
   - HTTPS will be available if you configure a domain (see below)

2. **Use your own domain** (optional):
   - **Make sure the domain variable was set**: In the `terraform.tfvars` file the domain value should be set to the domain you have registered for Nightscout. If it's missing you'll need to add it and run `terraform apply` again.
   - **Point your domain**: Create an A record pointing to the public IP:

     ```
     A record: nightscout.yourdomain.com → <public-ip-address>
     ```

3. **Monitor the service**:
   - **SSH into server**: Use the `ssh_command` output
   - **Check service status**: `sudo systemctl status nightscout`
   - **View logs**: `cd /opt/nightscout && sudo docker-compose logs -f`
   - **Restart services**: `sudo systemctl restart nightscout`

4. **Update configurations**:
   - **Recommended**: Update secrets in OCI Vault via console or CLI
   - Changes are automatically detected and applied within 15 minutes
   - **Add new variables**: Simply add new secrets to the vault with uppercase snake_case names
   - **Alternative**: Edit `/opt/nightscout/.env` directly (manual restart required)
   - **Monitoring**: Check rotation logs at `/var/log/nightscout-secret-rotation.log`

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
cd /opt/nightscout && sudo docker compose logs -f

# Restart services
cd /opt/nightscout && sudo docker compose restart

# Update Nightscout image
cd /opt/nightscout && sudo docker compose pull && sudo docker compose up -d

# Check secret rotation logs
tail -f /var/log/nightscout-secret-rotation.log

# Manually trigger secret rotation
sudo /opt/nightscout/rotate-secrets.sh
```

## Troubleshooting

**If Nightscout isn't starting:**

1. SSH into the server: `ssh opc@<public-ip>`
2. Check logs: `cd /opt/nightscout && sudo docker-compose logs nightscout`
3. Verify configuration: `cat /opt/nightscout/.env`
4. Restart services: `sudo docker compose restart`

**If you can't access the web interface:**

1. Check if services are running: `sudo docker compose ps`
2. Verify ports are open: `sudo firewall-cmd --list-all` (if firewall is enabled)
3. Check security list allows HTTP/HTTPS traffic in OCI console

**For domain/SSL issues:**

1. Verify DNS points to the correct IP: `nslookup yourdomain.com`
2. Check Caddy logs: `sudo docker-compose logs caddy`
3. Ensure port 443 is accessible from the internet
