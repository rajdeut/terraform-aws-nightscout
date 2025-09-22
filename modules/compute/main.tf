# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# Get latest Oracle Linux image
data "oci_core_images" "oracle_linux" {
  compartment_id   = var.compartment_id
  operating_system = "Oracle Linux"
  shape            = "VM.Standard.E2.1.Micro"

  filter {
    name   = "display_name"
    values = [".*Oracle-Linux-8.*"]
    regex  = true
  }
}

# Create compute instance for Nightscout
resource "oci_core_instance" "nightscout" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  display_name        = "nightscout-server"
  shape               = "VM.Standard.E2.1.Micro"  # Always Free eligible

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
    user_data          = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      secret_id = var.secret_id
    }))
  }

  freeform_tags = var.tags
}

# Create dynamic group for compute instance
resource "oci_identity_dynamic_group" "nightscout_instance_group" {
  compartment_id = var.compartment_id
  name           = "nightscout-instance-group"
  description    = "Dynamic group for Nightscout compute instances"
  matching_rule  = "instance.id = '${oci_core_instance.nightscout.id}'"
  freeform_tags  = var.tags
}

# Create policy to allow compute instance to read secrets
resource "oci_identity_policy" "nightscout_secrets_policy" {
  compartment_id = var.compartment_id
  name           = "nightscout-secrets-policy"
  description    = "Policy allowing Nightscout instance to read secrets"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.nightscout_instance_group.name} to read secret-family in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.nightscout_instance_group.name} to use keys in compartment id ${var.compartment_id}"
  ]

  freeform_tags = var.tags
}

# Public IP will be assigned automatically via create_vnic_details