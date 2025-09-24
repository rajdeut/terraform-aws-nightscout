#!/bin/bash

# Secret rotation script for Nightscout
LOG_FILE="/var/log/nightscout-secret-rotation.log"

log_message() {
  echo "$(date): $1" | sudo tee -a "$LOG_FILE"
}

# Get vault ID and compartment ID from template
VAULT_ID='${vault_id}'
COMPARTMENT_ID='${compartment_id}'

# Export path for OCI CLI
export PATH=$PATH:/home/opc/bin

# Verify OCI CLI is available
if ! command -v /home/opc/bin/oci &> /dev/null; then
  log_message "ERROR: OCI CLI not found at /home/opc/bin/oci"
  exit 1
fi

# Discover all secrets in the vault
secrets_json=$(/home/opc/bin/oci vault secret list --compartment-id "$COMPARTMENT_ID" --vault-id "$VAULT_ID" --auth instance_principal --all 2>&1)
if [[ $? -ne 0 ]]; then
  log_message "Failed to list secrets from vault: $secrets_json"
  exit 1
fi

# Extract all ACTIVE secrets (assume all secrets in this vault are environment variables)
SECRET_OCIDS=$(echo "$secrets_json" | jq -r '.data[] | select(."lifecycle-state" == "ACTIVE") | "\(.name):\(.id)"' | tr '\n' ' ')

if [[ -z "$SECRET_OCIDS" ]]; then
  log_message "No active secrets found in vault"
  exit 1
fi

# Create temporary env file
TEMP_ENV="/tmp/.env.new"
TEMP_ENV_COMPARE="/tmp/.env.compare"

echo "# Nightscout environment variables" > "$TEMP_ENV"
echo "# Updated on $(date)" >> "$TEMP_ENV"
echo "" >> "$TEMP_ENV"

# Create comparison file without timestamp
echo "# Nightscout environment variables" > "$TEMP_ENV_COMPARE"
echo "" >> "$TEMP_ENV_COMPARE"

# Fetch each secret
ALL_SECRETS_FETCHED=true
for secret_pair in $SECRET_OCIDS; do
  # Split name:ocid pair
  secret_name=$(echo "$secret_pair" | cut -d':' -f1)
  secret_ocid=$(echo "$secret_pair" | cut -d':' -f2)

  # Normalize secret name to uppercase snake_case environment variable format
  env_var=$(echo "$secret_name" | sed 's/-/_/g' | tr '[:lower:]' '[:upper:]')

  if [[ -n "$secret_ocid" ]]; then
    # Try fetching secret
    oci_output=$(/home/opc/bin/oci secrets secret-bundle get --secret-id "$secret_ocid" --auth instance_principal --query 'data."secret-bundle-content".content' --raw-output 2>&1)
    oci_exit_code=$?

    if [[ $oci_exit_code -eq 0 ]]; then
      secret_value=$(echo "$oci_output" | base64 -d 2>&1)
      base64_exit_code=$?

      if [[ $base64_exit_code -eq 0 && -n "$secret_value" ]]; then
        echo "$env_var=$secret_value" >> "$TEMP_ENV"
        echo "$env_var=$secret_value" >> "$TEMP_ENV_COMPARE"
      else
        log_message "Failed to decode secret for $env_var"
        ALL_SECRETS_FETCHED=false
      fi
    else
      log_message "Failed to fetch secret for $env_var: $oci_output"
      ALL_SECRETS_FETCHED=false
    fi
  else
    log_message "Invalid secret OCID for $env_var"
    ALL_SECRETS_FETCHED=false
  fi
done

# Only update if all secrets were fetched successfully
if [[ "$ALL_SECRETS_FETCHED" == "true" ]]; then
  # Create comparison version of existing file (without timestamp)
  EXISTING_ENV_COMPARE="/tmp/.env.existing.compare"

  if [[ -f "/opt/nightscout/.env" ]]; then
    # Remove timestamp line and empty lines from existing file for comparison
    grep -v "^# Updated on " /opt/nightscout/.env | grep -v "^$" > "$EXISTING_ENV_COMPARE" || true
    # Add back the header and empty line for consistency
    sed -i '1i# Nightscout environment variables\n' "$EXISTING_ENV_COMPARE"
  else
    # No existing file, so comparison file should be empty
    touch "$EXISTING_ENV_COMPARE"
  fi

  # Compare with existing file (without timestamps)
  if ! cmp -s "$TEMP_ENV_COMPARE" "$EXISTING_ENV_COMPARE"; then
    log_message "Secrets updated, restarting services"

    # Backup old env file if it exists
    if [[ -f "/opt/nightscout/.env" ]]; then
      cp /opt/nightscout/.env /opt/nightscout/.env.backup
    fi

    # Update env file (with timestamp)
    mv "$TEMP_ENV" /opt/nightscout/.env
    chmod 600 /opt/nightscout/.env
    chown opc:opc /opt/nightscout/.env

    # Restart Nightscout service
    cd /opt/nightscout && sudo docker compose restart nightscout

    log_message "Services restarted successfully"
  fi

  # Clean up temp files
  rm -f "$TEMP_ENV" "$TEMP_ENV_COMPARE" "$EXISTING_ENV_COMPARE"
else
  log_message "Secret fetch failed, keeping existing configuration"
  rm -f "$TEMP_ENV" "$TEMP_ENV_COMPARE"
  exit 1
fi