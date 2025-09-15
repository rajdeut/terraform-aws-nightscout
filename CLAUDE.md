# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a Terraform infrastructure project that deploys Nightscout (a continuous glucose monitoring web application) on Google Cloud Platform (GCP) using Cloud Run. The infrastructure provides a simple, serverless hosting solution that scales automatically and includes HTTPS by default.

## Common Commands

### Terraform Operations
- `terraform init` - Initialize Terraform (required after cloning or when changing providers)
- `terraform plan` - Preview changes before applying
- `terraform apply` - Deploy the infrastructure
- `terraform apply -var="project_id=your-gcp-project"` - Deploy with project ID
- `terraform destroy` - Remove all infrastructure

### GCP Setup Requirements
- Install the Google Cloud SDK: `curl https://sdk.cloud.google.com | bash`
- Authenticate: `gcloud auth login`
- Set project: `gcloud config set project YOUR_PROJECT_ID`
- Enable required APIs: `gcloud services enable run.googleapis.com secretmanager.googleapis.com iam.googleapis.com cloudresourcemanager.googleapis.com`
- Create service account key and place in `config/gcp-credentials.json`

## Architecture Overview

### Module Structure
The project uses a modular Terraform architecture with the following components:

1. **Cloud Run Module** (`modules/cloud_run/`) - Manages the serverless container deployment:
   - Cloud Run service running the official Nightscout Docker image
   - Automatic scaling with configurable max instances
   - Environment variables sourced from Secret Manager
   - Public access configured with IAM policies

2. **Secrets Module** (`modules/secrets/`) - Stores Nightscout configuration in Google Secret Manager

3. **Service Account Module** (`modules/service_account/`) - Service account and IAM roles for Cloud Run to access Secret Manager

### Key Infrastructure Components
- **Cloud Storage bucket** for deployment artifacts (prefix: "nightscout-deployments-")
- **Cloud Run service** running the Nightscout Docker container
- **HTTPS by default** with automatic SSL certificate management by Google
- **Secret Manager** for secure configuration storage
- **Automatic scaling** based on request traffic

### Configuration Management
- GCP credentials stored in `config/gcp-credentials.json`
- Nightscout configuration in `config/nightscout.env` (simple KEY="value" format)
- All resources labeled with environment and application identifiers

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
- `project_id` (required) - GCP Project ID
- `region` (optional, default: us-central1) - GCP region for Cloud Run service
- `labels` (optional) - Map of labels for resource organization

## Development Notes
- Provider version uses Google provider ~> 5.0
- Uses official Nightscout Docker image from Docker Hub
- Resource naming convention: "nightscout-[resource_type]"
- Serverless architecture with automatic scaling
- HTTPS enabled by default with Google-managed SSL certificates

## Cloud Run Benefits
- **Serverless**: No server management required
- **Automatic HTTPS**: SSL certificates managed by Google
- **Auto-scaling**: Scales to zero when not in use, scales up based on traffic
- **Cost-effective**: Pay only for requests and actual usage
- **No firewall management**: Cloud Run handles all networking
- **Container-based**: Uses the official Nightscout Docker image
- **Free tier protection**: Built-in controls to prevent exceeding Google Cloud free limits

## Free Tier Protection
The deployment includes automatic controls to stay within Google Cloud's free tier:

- **Scaling limits**: Maximum 3 concurrent instances, scales to zero when idle
- **Resource limits**: 1 vCPU and 1GiB memory per instance (free tier maximums)
- **CPU throttling**: Enabled to reduce compute costs
- **Request optimization**: Designed for 2 million requests/month free allowance

**Google Cloud Free Tier includes:**
- 2 million Cloud Run requests per month
- 400,000 GiB-seconds of memory per month
- 200,000 vCPU-seconds of compute per month
- 1 GiB outbound data transfer per month