#!/bin/bash

# Sync secrets from Google Secret Manager to local .env file
# Optimized version with parallel processing and timeout protection

PROJECT_ID="[[PROJECT_ID]]"

# Create temporary env file
TEMP_ENV="/tmp/nightscout_env"
CURRENT_ENV="/etc/nightscout/environment"

echo "Starting secret sync at $(date)"

# Clear temp file
> "$TEMP_ENV"

echo "Retrieving nightscout secrets..."

# Get all nightscout secrets in one call
SECRETS_FOUND=$(gcloud secrets list --format="value(name)" 2>/dev/null | grep "^nightscout-")

if [ -z "$SECRETS_FOUND" ]; then
    echo "No nightscout secrets found in Secret Manager"
    exit 0
fi

SECRET_COUNT=$(echo "$SECRETS_FOUND" | wc -l)
echo "Found $SECRET_COUNT secrets to process"

# Function to process a single secret
process_secret() {
    local secret_name="$1"
    local counter="$2"

    echo "[$counter/$SECRET_COUNT] Processing: $secret_name"

    local var_name=$(echo "$secret_name" | sed 's/nightscout-//' | tr '[:lower:]' '[:upper:]' | tr '-' '_')

    # Use timeout with shorter duration and better error handling
    local secret_value=$(timeout 15 gcloud secrets versions access latest --secret="$secret_name" --quiet 2>/dev/null)
    local exit_code=$?

    if [ $exit_code -eq 0 ] && [ -n "$secret_value" ]; then
        echo "${var_name}=\"${secret_value}\"" >> "$TEMP_ENV"
        echo "  ✓ $secret_name: Success"
        return 0
    else
        echo "  ✗ $secret_name: Failed (exit code: $exit_code)"
        return 1
    fi
}

# Process secrets with limited concurrency to avoid API limits
COUNTER=1
BATCH_SIZE=5
PIDS=()

for secret_name in $SECRETS_FOUND; do
    # Start background process
    process_secret "$secret_name" "$COUNTER" &
    PIDS+=($!)

    COUNTER=$((COUNTER + 1))

    # Wait for batch to complete before starting next batch
    if [ ${#PIDS[@]} -ge $BATCH_SIZE ]; then
        for pid in "${PIDS[@]}"; do
            wait $pid
        done
        PIDS=()
        echo "Completed batch, continuing..."
    fi
done

# Wait for any remaining background processes
for pid in "${PIDS[@]}"; do
    wait $pid
done

echo "Completed processing all secrets at $(date)"
echo "Generated $(wc -l < "$TEMP_ENV") environment variables"

# Check if the env file has changed
if [ ! -f "$CURRENT_ENV" ] || ! cmp "$TEMP_ENV" "$CURRENT_ENV" --silent; then
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$CURRENT_ENV")"

    # Copy new env file and restart service
    cp "$TEMP_ENV" "$CURRENT_ENV"
    chown root:root "$CURRENT_ENV"
    chmod 600 "$CURRENT_ENV"

    echo "Environment file updated, restarting nightscout service..."
    systemctl restart nightscout.service
else
    echo "No changes to environment variables"
fi

# Clean up temp file
rm -f "$TEMP_ENV"