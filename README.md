# Terraform for Nightscout running on Google Cloud Platform (free-tier)
[![License: MIT](https://img.shields.io/badge/License-MIT-brightgreen.svg)](./LICENSE)

### Description
This Terraform project deploys a Nightscout instance on Google Cloud Platform (GCP) using free-tier resources. The infrastructure provides a simple, cost-effective hosting solution while maintaining the reliability and features of the Nightscout continuous glucose monitoring application.

While every effort has been made to ensure only free-tier resources are used, this may change as Google adjusts their offering and we take no responsibility for the services deployed to your own GCP account. You can read more about what services are offered in their [free-tier here](https://cloud.google.com/free).


### Prerequisites
1. **Google Cloud Platform Setup**:
   - **Create a new GCP project**:
     - Go to the [Google Cloud Console](https://console.cloud.google.com/)
     - Click "Select a project" → "New Project"
     - Enter a project name (e.g., "nightscout-hosting")
     - Note the **Project ID** that gets generated (e.g., "nightscout-hosting-123456") - you'll need this
   - **Enable billing** (required even for free tier usage):
     - In the Cloud Console, go to "Billing" and link a payment method
     - Don't worry - free tier resources won't charge you
   - **Create service account** (for Terraform authentication):
     - In the Cloud Console, go to "IAM & Admin" → "Service Accounts"
     - Click "Create Service Account"
     - Name: "terraform-nightscout", Description: "Service account for Terraform to deploy Nightscout"
     - Click "Create and Continue" → Grant role: "Owner" → Click "Done"
     - Click on your service account → "Keys" tab → "Add Key" → "Create new key" → Select "JSON"
     - **Important**: Rename the downloaded file to `gcp-credentials.json` and move it to the `config/` folder
   - **Install Google Cloud SDK**:
     - [Download and install](https://cloud.google.com/sdk/docs/install) or via HomeBrew: `brew install --cask google-cloud-sdk`
   - **Authenticate and configure**:
     - Run `gcloud auth login` to authenticate
     - Set your default project: `gcloud config set project YOUR_PROJECT_ID` (replace with your actual project ID)
     - Enable required APIs: `gcloud services enable compute.googleapis.com secretmanager.googleapis.com iam.googleapis.com cloudresourcemanager.googleapis.com`

2. **Terraform Installation**:
   - Install [Terraform](https://www.terraform.io/downloads.html) (version 1.0+)

3. **Configuration Files**:
   - Copy `terraform.tfvars.example` to `terraform.tfvars` and update with your values
   - Copy `config/nightscout-config-example.json` to `config/nightscout.config.json` and update with your Nightscout settings
   - Generate SSH keys: `ssh-keygen -t rsa -f config/nightscout-compute-key`

### Installation
1. Clone this repository
2. Complete the prerequisites above
3. Run `terraform init`
4. Run `terraform plan` to review the infrastructure
5. Run `terraform apply` to deploy

The project is configured to access GCP credentials from `config/gcp-credentials.json` rather than system defaults. If you're experienced with Terraform and GCP, you may modify the `providers.tf` file to use different authentication methods.

### Terraform details
#### Inputs
- `project_id` (**required**) - Your GCP Project ID
- `region` (default: us-central1) - The GCP region to deploy resources (first available zone is automatically selected)
- `domain` (optional) - The domain name that will be pointing to your Nightscout instance. *(Required if using HTTPS and wanting automatic SSL generation)*
- `https` [true|false] (default: false) - If true, sets the Nightscout port to 443 instead of 80. When used with `domain` will generate an SSL via Let's Encrypt
- `compute_ssh_public_key_path` (default: config/nightscout-compute-key.pub) - Path to the public key to be installed on the Nightscout server
- `my_ip` (optional) - The IP address to whitelist for SSH access to the Nightscout server
- `labels` (optional) - Map of labels to apply to all resources for organization

#### Outputs
- `compute_public_ip` - The public IP address for the Nightscout instance
- `application_url` - The URL to access your Nightscout application
- `ssh_command` - The gcloud command to SSH into your server

### Free Tier Resources Used
- **Compute Engine**: e2-micro instance (744 hours/month free)
- **Secret Manager**: Up to 6 secrets (free tier)
- **Cloud Storage**: 5GB free storage for deployment artifacts
- **Networking**: 1GB egress per month (may exceed for active Nightscout usage)

### Automated Code Deployment
The GCP version includes **automated daily deployments** that replace AWS CodePipeline:

- **Daily Check**: Runs at 2 AM daily via cron job
- **Smart Updates**: Only deploys when new commits are available on GitHub
- **Safe Process**: Stops service → pulls code → installs deps → syncs config → restarts service
- **Full Logging**: All deployment activity logged to `/var/log/nightscout-auto-deploy.log`

**Manual Deployment Commands:**
```bash
# Force immediate deployment check
gcloud compute ssh nightscout-server --command="sudo /opt/nightscout/scripts/auto_deploy.sh"

# View deployment logs
gcloud compute ssh nightscout-server --command="sudo tail -f /var/log/nightscout-auto-deploy.log"

# Check last 20 deployment log entries
gcloud compute ssh nightscout-server --command="sudo tail -20 /var/log/nightscout-auto-deploy.log"
```

### Post-Deployment
After deployment, you can:
1. **Get your static IP**: Note the `compute_public_ip` from terraform output
2. **Configure DNS** (if using a domain):
   - Point your domain to the static IP address from step 1
   - Wait for DNS propagation (usually 5-60 minutes)
   - SSH into server and run: `sudo /opt/nightscout/scripts/setup_ssl.sh`
3. **Access your Nightscout**: Use the `application_url` output (HTTP initially, HTTPS after SSL setup)
4. **Monitor and manage**:
   - SSH into server: Use the `ssh_command` output
   - Monitor Nightscout logs: `sudo journalctl -u nightscout.service -f`
   - Monitor deployment logs: `sudo tail -f /var/log/nightscout-auto-deploy.log`
   - Update configurations: Modify secrets in Google Secret Manager (auto-syncs hourly)