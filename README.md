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
     - Enable required APIs: `gcloud services enable run.googleapis.com secretmanager.googleapis.com iam.googleapis.com cloudresourcemanager.googleapis.com`

2. **Terraform Installation**:
   - Install [Terraform](https://www.terraform.io/downloads.html) (version 1.0+)

3. **Configuration Files**:
   - Copy `config/nightscout.env.example` to `config/nightscout.env` and update with your Nightscout settings

### Installation
1. Clone this repository
2. Complete the prerequisites above
3. Run `terraform init`
4. Run `terraform plan -var="project_id=your-gcp-project-id"` to review the infrastructure
5. Run `terraform apply -var="project_id=your-gcp-project-id"` to deploy. *(This may take 10+ minutes to complete)*

The project is configured to access GCP credentials from `config/gcp-credentials.json` rather than system defaults. If you're experienced with Terraform and GCP, you may modify the `providers.tf` file to use different authentication methods.

### Terraform details
#### Inputs
- `project_id` (**required**) - Your GCP Project ID
- `region` (optional, default: us-central1) - The GCP region to deploy the Cloud Run service
- `labels` (optional) - Map of labels to apply to all resources for organization

#### Outputs
- `application_url` - The HTTPS URL to access your Nightscout application

### Post-Deployment

After deployment, you can:

1. **Access your Nightscout**: Use the `application_url` output (HTTPS by default)

2. **Use your own domain** (optional):
   - **Point your domain**: Create a CNAME record pointing to your Cloud Run URL (without https://)
     ```
     CNAME: nightscout.yourdomain.com → your-service-hash-region.a.run.app
     ```
   - **Map the domain**: Run this command to map your domain to Cloud Run:
     ```bash
     gcloud run domain-mappings create --service=nightscout --domain=nightscout.yourdomain.com --region=your-region
     ```
   - **Update BASE_URL** (optional): Add this to your `config/nightscout.env`:
     ```
     BASE_URL="https://nightscout.yourdomain.com"
     ```
   - Then run `terraform apply` to update the configuration.

3. **Monitor the service**:
   - View logs: `gcloud logs tail --follow --project=your-project-id --filter="resource.labels.service_name=nightscout"`
   - Check service status: `gcloud run services describe nightscout --region=your-region`

4. **Update configurations**:
   - Edit `config/nightscout.env` and run `terraform apply` again
   - Or modify secrets directly in Google Secret Manager console

### Free Tier Protection

This deployment includes built-in controls to stay within Google Cloud's free tier:

- **Max 3 concurrent instances**: Prevents excessive scaling
- **Scales to zero**: No charges when not in use
- **CPU throttling enabled**: Reduces compute costs
- **Resource limits**: 1 vCPU and 1GiB memory per instance (free tier limits)
- **Request limits**: Designed to stay within 2 million requests/month free allowance

**Monthly free tier includes:**

- 2 million requests
- 400,000 GiB-seconds of memory
- 200,000 vCPU-seconds of compute time
- 1 GiB of outbound data transfer
