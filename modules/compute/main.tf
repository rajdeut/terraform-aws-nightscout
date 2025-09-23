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
      env_content = base64decode(var.env_content)
      domain      = var.domain
    }))
  }

  freeform_tags = var.tags
}

# Public IP will be assigned automatically via create_vnic_details
