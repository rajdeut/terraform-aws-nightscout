# Get Ubuntu 22.04 LTS image
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

# Construct the startup script
locals {
  startup_script = file("${path.module}/resources/startup_script.sh")
  replacement_map = {
    SYNC_SECRETS = replace(file("${path.module}/resources/sync_secrets.sh"), "[[PROJECT_ID]]", var.project_id)
    AUTO_DEPLOY  = file("${path.module}/resources/auto_deploy.sh")
    LETSENCRYPT  = var.port == 443 && var.domain != null ? replace(file("${path.module}/resources/letsencrypt.sh"), "[[DOMAIN]]", var.domain) : ""
  }
  startup_script_final = replace(
    replace(
      replace(
        local.startup_script,
        "[[SYNC_SECRETS]]",
        local.replacement_map.SYNC_SECRETS
      ),
      "[[AUTO_DEPLOY]]",
      local.replacement_map.AUTO_DEPLOY
    ),
    "[[LETSENCRYPT]]",
    local.replacement_map.LETSENCRYPT
  )
}

# Create static IP address
resource "google_compute_address" "nightscout_static_ip" {
  name   = "nightscout-static-ip"
  region = var.region
}

# Create the compute instance
resource "google_compute_instance" "nightscout_server" {
  name         = "nightscout-server"
  machine_type = "e2-micro"  # Free tier eligible
  zone         = var.zone

  tags = ["nightscout-server"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 30  # 30GB as recommended by GCP instructions
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name

    access_config {
      nat_ip = google_compute_address.nightscout_static_ip.address
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = var.ssh_public_key_path != null ? "root:${file(var.ssh_public_key_path)}" : ""
  }

  metadata_startup_script = local.startup_script_final

  labels = var.labels

  # Allow stopping for metadata changes
  allow_stopping_for_update = true
}