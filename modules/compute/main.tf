# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# Create dynamic group for the instance to access secrets
resource "oci_identity_dynamic_group" "nightscout_dynamic_group" {
  compartment_id = var.compartment_id
  description    = "Dynamic group for Nightscout instance to access vault secrets"
  matching_rule  = "instance.id = '${oci_core_instance.nightscout.id}'"
  name           = "nightscout-instance-group"

  freeform_tags = var.tags
}

# Create policy to allow the dynamic group to read secrets
resource "oci_identity_policy" "nightscout_secrets_policy" {
  compartment_id = var.compartment_id
  description    = "Policy allowing Nightscout instance to read vault secrets"
  name           = "nightscout-secrets-policy"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.nightscout_dynamic_group.name} to read secret-family in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.nightscout_dynamic_group.name} to read vaults in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.nightscout_dynamic_group.name} to use keys in compartment id ${var.compartment_id}"
  ]

  freeform_tags = var.tags
}

# Get latest Oracle Linux image
data "oci_core_images" "oracle_linux" {
  compartment_id   = var.compartment_id
  operating_system = "Oracle Linux"
  shape            = "VM.Standard.E2.1.Micro"

  filter {
    name   = "display_name"
    values = [".*Oracle-Linux-9.*"]
    regex  = true
  }
}

# Create compute instance for Nightscout
resource "oci_core_instance" "nightscout" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  display_name        = "nightscout-server"
  shape               = "VM.Standard.E2.1.Micro" # Always Free eligible

  create_vnic_details {
    subnet_id                 = var.subnet_id
    display_name              = "nightscout-vnic"
    assign_public_ip          = true
    assign_private_dns_record = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data = base64encode(templatefile("${path.module}/oci-cloud-init.sh", {
      vault_id           = var.vault_id
      secret_ocids       = jsonencode(var.secret_ocids)
      env_vars           = jsonencode(var.env_vars)
      domain             = var.domain
      caddyfile_content  = templatefile("${path.module}/templates/Caddyfile.tpl", { domain = var.domain })
      compose_content    = file("${path.module}/templates/docker-compose.yml.tpl")
      rotate_script_content = templatefile("${path.module}/templates/rotate-secrets.sh.tpl", {
        secret_ocids = jsonencode(var.secret_ocids)
        env_vars     = jsonencode(var.env_vars)
      })
      systemd_content    = file("${path.module}/templates/nightscout.service.tpl")
    }))
  }

  freeform_tags = var.tags
}

# Public IP will be assigned automatically via create_vnic_details
