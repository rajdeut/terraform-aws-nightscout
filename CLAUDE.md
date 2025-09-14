# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a Terraform infrastructure project that deploys Nightscout (a continuous glucose monitoring web application) on Google Cloud Platform (GCP) using free-tier resources. The infrastructure provides a simple, cost-effective hosting solution using GCP services.

## Common Commands

### Terraform Operations
- `terraform init` - Initialize Terraform (required after cloning or when changing providers)
- `terraform plan` - Preview changes before applying
- `terraform apply` - Deploy the infrastructure
- `terraform apply -var="project_id=your-gcp-project" -var="domain=example.com" -var="my_ip=x.x.x.x" -var="https=true"` - Deploy with variables
- `terraform destroy` - Remove all infrastructure

### GCP Setup Requirements
- Install the Google Cloud SDK: `curl https://sdk.cloud.google.com | bash`
- Authenticate: `gcloud auth login`
- Set project: `gcloud config set project YOUR_PROJECT_ID`
- Enable required APIs: `gcloud services enable compute.googleapis.com secretmanager.googleapis.com`
- Create service account key and place in `config/gcp-credentials.json`

## Architecture Overview

### Module Structure
The project uses a modular Terraform architecture with the following components:

1. **Network Module** (`modules/network/`) - Creates the network infrastructure:
   - VPC network with regional routing
   - Subnet with CIDR 10.0.1.0/24
   - Firewall rules for HTTP/HTTPS, SSH, and MongoDB access

2. **Compute Module** (`modules/compute/`) - Manages the compute resources:
   - Ubuntu 22.04 LTS Compute Engine instance running Nightscout
   - e2-micro instance type (free tier eligible)
   - Automated startup script with Node.js and Nightscout installation
   - SSH key management via metadata

3. **Secrets Module** (`modules/secrets/`) - Stores Nightscout configuration in Google Secret Manager

4. **Service Account Module** (`modules/service_account/`) - Service account and IAM roles for Compute Engine to access Secret Manager

### Key Infrastructure Components
- **Cloud Storage bucket** for deployment artifacts (prefix: "nightscout-deployments-")
- **Compute Engine instance** running on free-tier with public IP
- **Firewall rules** allowing HTTP (80), HTTPS (443), SSH (22), and MongoDB (27017)
- **Let's Encrypt SSL** automatic generation when HTTPS is enabled with domain
- **Secret Manager** for secure configuration storage
- **Automated deployments** via daily cron job that checks GitHub for updates

### Configuration Management
- GCP credentials stored in `config/gcp-credentials.json`
- SSH public key path: `config/nightscout-compute-key.pub` (default)
- All resources labeled with environment and application identifiers

## Important Variables
- `project_id` (required) - GCP Project ID
- `region` (optional, default: us-central1) - GCP region for resources (first zone auto-selected)
- `domain` (optional) - Domain name for HTTPS with automatic SSL
- `https` (true/false) - Enables HTTPS on port 443 vs HTTP on port 80
- `my_ip` (optional) - IP address for SSH access restriction
- `compute_ssh_public_key_path` - Path to SSH public key file
- `labels` (optional) - Map of labels for resource organization

## Development Notes
- Provider version uses Google provider ~> 5.0
- Uses startup script with template replacement for automated setup
- Resource naming convention: "nightscout-[resource_type]"
- All infrastructure designed for GCP free-tier usage
- Ubuntu 22.04 LTS used as base OS for better compatibility

## Automated Deployment System
The infrastructure includes a built-in automated deployment system that replaces AWS CodePipeline:

### Deployment Schedule
- **Frequency**: Daily at 2:00 AM (configurable via cron)
- **Script**: `/opt/nightscout/scripts/auto_deploy.sh`
- **Logging**: Full deployment logs at `/var/log/nightscout-auto-deploy.log`

### Deployment Process
1. **Update Check**: Fetches from GitHub and compares commit hashes
2. **Conditional Deploy**: Only proceeds if new commits are available
3. **Safe Process**:
   - Stops Nightscout service
   - Pulls latest code (`git reset --hard origin/master`)
   - Installs/updates NPM dependencies
   - Syncs configuration from Secret Manager
   - Restarts service and validates it's running
4. **Error Handling**: Automatic rollback if deployment fails

### Manual Operations
```bash
# Force deployment check
sudo /opt/nightscout/scripts/auto_deploy.sh

# View deployment logs
sudo tail -f /var/log/nightscout-auto-deploy.log

# Check service status
sudo systemctl status nightscout.service
```