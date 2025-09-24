# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}


# Create dynamic group for the instance to access secrets
resource "oci_identity_dynamic_group" "nightscout_dynamic_group" {
  compartment_id = var.tenancy_id
  description    = "Dynamic group for Nightscout instance to access vault secrets"
  matching_rule  = "instance.id = '${oci_core_instance.nightscout.id}'"
  name           = "nightscout-instance-group"

  freeform_tags = var.tags
}

# Create policy to allow the dynamic group to read secrets
resource "oci_identity_policy" "nightscout_secrets_policy" {
  compartment_id = var.tenancy_id
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
    assign_public_ip          = false  # Don't assign ephemeral IP, we'll use reserved IP
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
      domain             = var.domain
      caddyfile_content  = templatefile("${path.module}/templates/Caddyfile.tpl", { domain = var.domain })
      compose_content    = file("${path.module}/templates/docker-compose.yml.tpl")
      rotate_script_content = templatefile("${path.module}/templates/rotate-secrets.sh.tpl", {
        vault_id       = var.vault_id
        compartment_id = var.compartment_id
      })
      systemd_content    = file("${path.module}/templates/nightscout.service.tpl")
    }))
  }

  freeform_tags = var.tags
}

# Get the VNIC attachments for the instance
data "oci_core_vnic_attachments" "nightscout_vnic_attachments" {
  compartment_id = var.compartment_id
  instance_id    = oci_core_instance.nightscout.id
}

# Get the private IPs for the VNIC
data "oci_core_private_ips" "nightscout_private_ips" {
  vnic_id = data.oci_core_vnic_attachments.nightscout_vnic_attachments.vnic_attachments[0].vnic_id
}

# Create reserved public IP and attach to the instance VNIC
resource "oci_core_public_ip" "nightscout_reserved_ip" {
  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = "nightscout-reserved-ip"
  private_ip_id  = data.oci_core_private_ips.nightscout_private_ips.private_ips[0].id

  freeform_tags = var.tags
}
