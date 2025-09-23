# Create dedicated compartment for Nightscout in the root tenancy
resource "oci_identity_compartment" "nightscout" {
  name          = var.compartment_name
  description   = var.compartment_description
  freeform_tags = var.tags
}
