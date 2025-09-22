# Get current tenancy for compartment creation
data "oci_identity_tenancy" "current" {}

# Create dedicated compartment for Nightscout
resource "oci_identity_compartment" "nightscout" {
  compartment_id = data.oci_identity_tenancy.current.id
  name           = var.compartment_name
  description    = var.compartment_description
  freeform_tags  = var.tags
}