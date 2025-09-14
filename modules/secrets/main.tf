# Setup secrets in Google Secret Manager
locals {
  # Load configuration from JSON file if it exists
  params = jsondecode(fileexists("${path.module}/../../config/nightscout.config.json") ? file("${path.module}/../../config/nightscout.config.json") : "{}")
}

# Create secrets from the nightscout config file
resource "google_secret_manager_secret" "config_secrets" {
  for_each  = { for idx, v in local.params : idx => v }
  secret_id = "nightscout-${lower(each.value.name)}"

  labels = var.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "config_secret_versions" {
  for_each    = google_secret_manager_secret.config_secrets
  secret      = each.value.id
  secret_data = local.params[each.key].value
}

# Port configuration
resource "google_secret_manager_secret" "port_secret" {
  secret_id = "nightscout-port"
  labels    = var.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "port_secret_version" {
  secret      = google_secret_manager_secret.port_secret.id
  secret_data = tostring(var.port)
}

# HTTP/HTTPS configuration
resource "google_secret_manager_secret" "insecure_use_http_secret" {
  secret_id = "nightscout-insecure-use-http"
  labels    = var.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "insecure_use_http_secret_version" {
  secret      = google_secret_manager_secret.insecure_use_http_secret.id
  secret_data = var.port == 80 ? "true" : "false"
}

# SSL certificate paths (only created if domain is provided and HTTPS is enabled)
resource "google_secret_manager_secret" "ssl_key_secret" {
  count     = var.port == 443 && var.domain != null ? 1 : 0
  secret_id = "nightscout-ssl-key"
  labels    = var.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "ssl_key_secret_version" {
  count       = var.port == 443 && var.domain != null ? 1 : 0
  secret      = google_secret_manager_secret.ssl_key_secret[0].id
  secret_data = "/etc/letsencrypt/live/${lower(var.domain)}/privkey.pem"
}

resource "google_secret_manager_secret" "ssl_cert_secret" {
  count     = var.port == 443 && var.domain != null ? 1 : 0
  secret_id = "nightscout-ssl-cert"
  labels    = var.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "ssl_cert_secret_version" {
  count       = var.port == 443 && var.domain != null ? 1 : 0
  secret      = google_secret_manager_secret.ssl_cert_secret[0].id
  secret_data = "/etc/letsencrypt/live/${lower(var.domain)}/fullchain.pem"
}

resource "google_secret_manager_secret" "ssl_ca_secret" {
  count     = var.port == 443 && var.domain != null ? 1 : 0
  secret_id = "nightscout-ssl-ca"
  labels    = var.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "ssl_ca_secret_version" {
  count       = var.port == 443 && var.domain != null ? 1 : 0
  secret      = google_secret_manager_secret.ssl_ca_secret[0].id
  secret_data = "/etc/letsencrypt/live/${lower(var.domain)}/chain.pem"
}