#!/bin/bash

# Secret rotation script for Nightscout
LOG_FILE="/var/log/nightscout-secret-rotation.log"

log_message() {
  echo "$(date): $1" | sudo tee -a "$LOG_FILE"
}

# Parse JSON variables from template (same as during initial setup)
SECRET_OCIDS='${secret_ocids}'
ENV_VARS='${env_vars}'

# Export path for OCI CLI
export PATH=$PATH:/home/opc/bin

# Create temporary env file
TEMP_ENV="/tmp/.env.new"
echo "# Nightscout environment variables" > "$TEMP_ENV"
echo "# Updated on $(date)" >> "$TEMP_ENV"
echo "" >> "$TEMP_ENV"

# Fetch each secret
ALL_SECRETS_FETCHED=true
for var in $(echo "$ENV_VARS" | jq -r '.[]'); do
  secret_ocid=$(echo "$SECRET_OCIDS" | jq -r ".[\"$var\"]")

  if [[ "$secret_ocid" != "null" && -n "$secret_ocid" ]]; then
    secret_value=$(/home/opc/bin/oci secrets secret-bundle get --secret-id "$secret_ocid" --auth instance_principal --query 'data."secret-bundle-content".content' --raw-output 2>/dev/null | base64 -d 2>/dev/null)

    if [[ $? -eq 0 && -n "$secret_value" ]]; then
      echo "$var=$secret_value" >> "$TEMP_ENV"
    else
      log_message "Warning: Failed to fetch secret for $var"
      ALL_SECRETS_FETCHED=false
    fi
  else
    log_message "Warning: No secret OCID found for $var"
    ALL_SECRETS_FETCHED=false
  fi
done

# Only update if all secrets were fetched successfully
if [[ "$ALL_SECRETS_FETCHED" == "true" ]]; then
  # Compare with existing file
  if ! cmp -s "$TEMP_ENV" "/opt/nightscout/.env"; then
    log_message "Secrets changed, updating configuration and restarting services"

    # Backup old env file
    cp /opt/nightscout/.env /opt/nightscout/.env.backup

    # Update env file
    mv "$TEMP_ENV" /opt/nightscout/.env
    chmod 600 /opt/nightscout/.env
    chown opc:opc /opt/nightscout/.env

    # Restart Nightscout service
    cd /opt/nightscout && sudo docker compose restart nightscout

    log_message "Services restarted with updated secrets"
  else
    log_message "No changes detected in secrets"
    rm -f "$TEMP_ENV"
  fi
else
  log_message "Some secrets failed to fetch, keeping existing configuration"
  rm -f "$TEMP_ENV"
fi