# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a Terraform infrastructure project that deploys Nightscout (a continuous glucose monitoring web application) on Oracle Cloud Infrastructure (OCI) using Always Free tier resources. The infrastructure provides a reliable, always-on hosting solution with automatic SSL via Caddy reverse proxy.

## Common Commands

### Terraform Operations
- `terraform init` - Initialize Terraform (required after cloning or when changing providers)
- `terraform plan` - Preview changes before applying
- `terraform apply` - Deploy the infrastructure (creates compartment automatically)
- `terraform apply -var="ssh_public_key_path=~/.ssh/id_rsa.pub"` - Deploy with system SSH key
- `terraform apply -var="region=us-phoenix-1"` - Deploy to different region
- `terraform destroy` - Remove all infrastructure (including compartment)

### Using terraform.tfvars (Optional)
For easier customization, copy the example file:
- `cp terraform.tfvars.example terraform.tfvars`
- Edit `terraform.tfvars` with your preferences
- Run `terraform apply` (automatically uses tfvars)

### OCI Setup Requirements
- Install the OCI CLI: [Installation Guide](https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.23.2/OCI_CLI_Installation_Guide.htm)
- Authenticate: `oci setup config`
- Note your tenancy OCID, user OCID, and region (compartment created automatically)
- Create project SSH key pair: `ssh-keygen -t rsa -b 2048 -f config/nightscout_ssh`

## Architecture Overview

### Module Structure
The project uses a modular Terraform architecture with the following components:

1. **Secrets Module** (`modules/secrets/`) - Manages secure configuration:
   - OCI Vault for storing Nightscout environment variables
   - KMS key for encryption
   - Secure base64-encoded secret storage

2. **Network Module** (`modules/network/`) - Creates the network infrastructure:
   - VCN (Virtual Cloud Network) with 10.0.0.0/16 CIDR
   - Public subnet with 10.0.1.0/24 CIDR
   - Internet Gateway for outbound connectivity
   - Security Lists allowing HTTP (80), HTTPS (443), and SSH (22)

3. **Compute Module** (`modules/compute/`) - Manages the compute resources:
   - VM.Standard.E2.1.Micro instance (Always Free eligible)
   - Oracle Linux 8 with cloud-init automation
   - Dynamic group and IAM policies for secrets access
   - Automatic Docker, Caddy, and Nightscout setup
   - Public IP assignment for internet access

### Key Infrastructure Components
- **Always Free Compute**: VM.Standard.E2.1.Micro (1/8 OCPU, 1GB memory)
- **Secure Secrets**: OCI Vault with KMS encryption for environment variables
- **Automatic Rotation**: Secret changes detected and applied every 10 minutes
- **Automatic HTTPS**: Caddy reverse proxy with Let's Encrypt SSL
- **Container-based**: Docker deployment of official Nightscout image
- **Dynamic Security**: Instance-based IAM policies for secure secrets access
- **Auto-restart**: Systemd service ensures containers restart on boot

### Configuration Management
- OCI credentials configured via `~/.oci/config` or environment variables
- Nightscout configuration stored securely in OCI Vault (encrypted with KMS)
- Local `config/nightscout.env` used only during Terraform deployment
- Instance fetches configuration automatically from vault at startup
- Automatic secret rotation checks every 10 minutes via cron job
- Container automatically restarts when secrets change
- All resources tagged with environment and application identifiers

### Configuration Format
The `config/nightscout.env` file uses a simple environment variable format:
```bash
# Comments start with #
MONGODB_URI="your-mongodb-connection-string"
API_SECRET="your-secret-key"
CUSTOM_TITLE="Your Nightscout Site"
# Enable features
ENABLE="careportal boluscalc food bwp cage sage"
```

This format is much easier to read and edit compared to JSON. Comments are supported using `#` at the beginning of a line.

## Important Variables

**Required Variables:**
- `tenancy_ocid` (required) - Your OCI tenancy OCID (from ~/.oci/config)

**Optional Variables:**
- `region` (default: us-ashburn-1) - OCI region for deployment
- `ssh_public_key_path` (default: ./config/nightscout_ssh.pub) - Path to SSH public key
- `ssh_allowed_cidr` (default: 0.0.0.0/0) - CIDR block for SSH access
- `tags` (default: production/nightscout/terraform tags) - Map of tags for resource organization

**Note**: Compartment "terraform-nightscout" is created automatically in your tenancy

## Development Notes
- Provider version uses Oracle OCI provider ~> 5.0
- Uses official Nightscout Docker image from Docker Hub
- Resource naming convention: "nightscout-[resource_type]"
- Always Free tier compatible - no usage charges
- Oracle Linux 8 as base OS for compatibility and support

## Always Free Tier Benefits
Oracle Cloud's Always Free tier provides excellent resources for Nightscout:

- **Always-on compute**: VM.Standard.E2.1.Micro runs 24/7 at no cost
- **Generous bandwidth**: 10 TB outbound data transfer per month
- **Persistent storage**: Up to 200 GB block storage included
- **No time limits**: Resources remain free indefinitely (not trial)
- **Multiple instances**: Can run up to 4 Always Free compute instances
- **Better specs**: 1/8 OCPU + 1GB RAM vs GCP's restrictive limits

## Container Architecture
The deployment uses a multi-container setup:

### Services
- **Caddy**: HTTP/HTTPS reverse proxy and SSL termination
  - Handles Let's Encrypt certificate automation
  - Routes traffic to Nightscout container
  - Supports custom domains with zero configuration

- **Nightscout**: Main CGM monitoring application
  - Runs on internal port 1337
  - Environment variables from `nightscout.env`
  - Persistent data storage via Docker volumes

### Management
- **Docker Compose**: Container orchestration and management
- **Systemd Service**: Ensures containers start on boot
- **Cloud-init**: Automated initial setup and configuration
- **Auto-restart**: Containers automatically restart on failure

## Post-Deployment Management

### Service Commands
```bash
# Check overall service status
sudo systemctl status nightscout

# View container logs
cd /opt/nightscout && docker-compose logs -f

# Restart all services
cd /opt/nightscout && docker-compose restart

# Update Nightscout to latest version
cd /opt/nightscout && docker-compose pull && docker-compose up -d
```

### Configuration Updates
**Recommended Approach:**
1. Update the secret in OCI Vault (via console or CLI)
2. Wait up to 10 minutes for automatic detection and restart
3. Monitor changes via `/var/log/nightscout-secret-rotation.log`

**Manual Approach:**
1. Edit `/opt/nightscout/.env` on the server
2. Run `cd /opt/nightscout && docker-compose restart nightscout`
3. Changes take effect immediately

### SSL/Domain Setup
1. Point your domain A record to the server's public IP
2. Edit `/opt/nightscout/Caddyfile` to add your domain
3. Restart Caddy: `docker-compose restart caddy`
4. Caddy automatically obtains SSL certificates

## Cost Optimization
This deployment is optimized for the Always Free tier:

- **$0 monthly cost**: All resources within Always Free limits
- **Efficient resource usage**: Containers minimize memory footprint
- **Minimal storage**: ~10-15GB used for OS and containers
- **No bandwidth concerns**: 10TB/month allowance is very generous
- **Always-on reliability**: No cold starts or scaling delays

## Troubleshooting Notes
- All logs available via `docker-compose logs [service-name]`
- Configuration stored in `/opt/nightscout/.env`
- Services managed by systemd service `nightscout.service`
- Network connectivity tested via security lists in OCI console
- SSL certificate issues typically resolve within 5-10 minutes

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.