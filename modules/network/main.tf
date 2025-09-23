# Create VCN (Virtual Cloud Network)
resource "oci_core_vcn" "nightscout_vcn" {
  compartment_id = var.compartment_id
  display_name   = "nightscout-vcn"
  cidr_block     = "10.0.0.0/16"
  dns_label      = "nightscoutvcn"

  freeform_tags = var.tags
}

# Create Internet Gateway
resource "oci_core_internet_gateway" "nightscout_ig" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.nightscout_vcn.id
  display_name   = "nightscout-internet-gateway"
  enabled        = true

  freeform_tags = var.tags
}

# Create default route table
resource "oci_core_default_route_table" "nightscout_rt" {
  manage_default_resource_id = oci_core_vcn.nightscout_vcn.default_route_table_id
  display_name               = "nightscout-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.nightscout_ig.id
  }

  freeform_tags = var.tags
}

# Create security list
resource "oci_core_security_list" "nightscout_sl" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.nightscout_vcn.id
  display_name   = "nightscout-security-list"

  # Egress rules - allow all outbound
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # Ingress rules
  # SSH access
  ingress_security_rules {
    protocol = "6" # TCP
    source   = var.ssh_allowed_cidr

    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP access
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS access
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 443
      max = 443
    }
  }

  freeform_tags = var.tags
}

# Create public subnet
resource "oci_core_subnet" "nightscout_subnet" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.nightscout_vcn.id
  display_name      = "nightscout-public-subnet"
  cidr_block        = "10.0.1.0/24"
  dns_label         = "nightscout"
  route_table_id    = oci_core_vcn.nightscout_vcn.default_route_table_id
  security_list_ids = [oci_core_security_list.nightscout_sl.id]

  freeform_tags = var.tags
}
