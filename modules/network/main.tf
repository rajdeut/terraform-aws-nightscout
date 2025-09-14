# Create VPC network
resource "google_compute_network" "vpc_network" {
  name                    = "nightscout-network"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

# Create subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "nightscout-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Create firewall rules for HTTP, HTTPS, and SSH
resource "google_compute_firewall" "http_https" {
  name    = "nightscout-allow-http-https"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nightscout-server"]
}

resource "google_compute_firewall" "ssh" {
  name    = "nightscout-allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = concat(var.ssh_source_ranges, ["35.235.240.0/20"])
  target_tags   = ["nightscout-server"]
}

# Allow MongoDB Atlas connections (port 27017)
resource "google_compute_firewall" "mongodb" {
  name    = "nightscout-allow-mongodb"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nightscout-server"]
}