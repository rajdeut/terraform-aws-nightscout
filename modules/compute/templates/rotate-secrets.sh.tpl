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

# Extract all ACTIVE secrets - try different field names
SECRET_LIST=$(echo "$secrets_json" | jq -r '.data[] | select(."lifecycle-state" == "ACTIVE") | "\(."secret-name" // .name // ."display-name" // "unnamed"):\(.id)"')

if [[ -z "$SECRET_LIST" ]]; then
  log_message "No active secrets found in vault"
  exit 1
fi

# Create temporary env file
TEMP_ENV="/tmp/.env.new"

echo "# Nightscout environment variables" > "$TEMP_ENV"
echo "" >> "$TEMP_ENV"

# Fetch each secret
ALL_SECRETS_FETCHED=true
while IFS= read -r secret_pair; do
  # Skip empty lines
  [[ -z "$secret_pair" ]] && continue

  # Split name:ocid pair (OCID contains multiple colons, so only split on first one)
  secret_name=$(echo "$secret_pair" | cut -d':' -f1)
  secret_ocid=$(echo "$secret_pair" | cut -d':' -f2-)

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
done <<< "$SECRET_LIST"

# Only update if all secrets were fetched successfully
if [[ "$ALL_SECRETS_FETCHED" == "true" ]]; then
  # Simple comparison - compare the files directly (no timestamps to worry about)
  if [[ ! -f "/opt/nightscout/.env" ]] || ! cmp -s "$TEMP_ENV" "/opt/nightscout/.env"; then
    log_message "Secrets updated, restarting services"

    # Backup old env file if it exists
    if [[ -f "/opt/nightscout/.env" ]]; then
      cp /opt/nightscout/.env /opt/nightscout/.env.backup
    fi

    # Update env file
    mv "$TEMP_ENV" /opt/nightscout/.env
    chmod 600 /opt/nightscout/.env
    chown opc:opc /opt/nightscout/.env

    # Restart Nightscout service
    cd /opt/nightscout && sudo docker compose restart nightscout

    log_message "Services restarted successfully"
  else
    # No changes, clean up temp file
    log_message "No changes in secrets"
    rm -f "$TEMP_ENV"
  fi
else
  log_message "Secret fetch failed, keeping existing configuration"
  rm -f "$TEMP_ENV"
  exit 1
fi