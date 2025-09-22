provider "oci" {
  # Authentication via config file or environment variables
  config_file_profile = "DEFAULT"

  # These can also be set via environment variables:
  # export TF_VAR_tenancy_ocid="ocid1.tenancy.oc1..your-tenancy-ocid"
  # export TF_VAR_user_ocid="ocid1.user.oc1..your-user-ocid"
  # export TF_VAR_fingerprint="your-key-fingerprint"
  # export TF_VAR_private_key_path="~/.oci/oci_api_key.pem"
  # export TF_VAR_region="us-ashburn-1"
}