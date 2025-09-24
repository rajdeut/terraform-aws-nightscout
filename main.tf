terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 7.0"
    }
  }
}

# ============================================================================
# Local Configuration
# ============================================================================

locals {
  # Standard tags applied to all resources
  tags = {
    Environment = "production"
    Application = "nightscout"
    ManagedBy   = "terraform"
  }

  # Read Nightscout environment configuration
  nightscout_env_content = fileexists("config/nightscout.env") ? file("config/nightscout.env") : ""
}

# ============================================================================
# Infrastructure Modules
# ============================================================================

# Create dedicated compartment for resource isolation
module "compartment" {
  source = "./modules/compartment"

  tags = local.tags
}

# Secure secrets management with OCI Vault
module "secrets" {
  source = "./modules/secrets"

  compartment_id         = module.compartment.compartment_id
  nightscout_env_content = local.nightscout_env_content
  tags                   = local.tags
}

# Network infrastructure (VCN, subnet, security lists)
module "network" {
  source = "./modules/network"

  compartment_id   = module.compartment.compartment_id
  ssh_allowed_cidr = var.ssh_allowed_cidr
  tags             = local.tags
}

# Compute instance with Nightscout deployment
module "compute" {
  source = "./modules/compute"

  compartment_id      = module.compartment.compartment_id
  tenancy_id          = module.compartment.tenancy_id
  subnet_id           = module.network.subnet_id
  ssh_public_key_path = var.ssh_public_key_path
  vault_id            = module.secrets.vault_id
  domain              = var.domain
  tags                = local.tags
}
