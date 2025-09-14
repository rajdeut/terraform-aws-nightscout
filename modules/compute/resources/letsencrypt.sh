# Setup Let's Encrypt SSL certificate (deferred)
echo "Preparing SSL certificate setup for domain: [[DOMAIN]]"
echo "IMPORTANT: Point your domain [[DOMAIN]] to this server's IP address first!"

# Create SSL setup script that can be run manually after DNS is configured
cat > /opt/nightscout/scripts/setup_ssl.sh << 'EOL'
#!/bin/bash
echo "Setting up Let's Encrypt SSL certificate for [[DOMAIN]]"
echo "Checking if domain points to this server..."

# Get current server's public IP
SERVER_IP=$(curl -s ifconfig.me)
DOMAIN_IP=$(dig +short [[DOMAIN]] | head -n1)

if [ "$SERVER_IP" = "$DOMAIN_IP" ]; then
    echo "✓ Domain [[DOMAIN]] correctly points to this server ($SERVER_IP)"

    # Stop Nightscout temporarily for standalone verification
    systemctl stop nightscout.service

    # Request SSL certificate using standalone mode
    certbot certonly \
      --standalone \
      --non-interactive \
      --agree-tos \
      --email webmaster@[[DOMAIN]] \
      --domains [[DOMAIN]]

    if [ $? -eq 0 ]; then
        echo "✓ SSL certificate obtained successfully for [[DOMAIN]]"

        # Create script to start Nightscout with SSL
        cat > /opt/nightscout/scripts/start_with_ssl.sh << 'SSL_EOL'
#!/bin/bash
export SSL_KEY="/etc/letsencrypt/live/[[DOMAIN]]/privkey.pem"
export SSL_CERT="/etc/letsencrypt/live/[[DOMAIN]]/fullchain.pem"
export HTTPS=true
systemctl restart nightscout.service
SSL_EOL
        chmod +x /opt/nightscout/scripts/start_with_ssl.sh

        # Start nightscout with SSL
        /opt/nightscout/scripts/start_with_ssl.sh

        # Set up auto-renewal via cron
        crontab -l > /tmp/current_cron || true
        echo "30 2 * * 1 certbot renew --quiet && /opt/nightscout/scripts/start_with_ssl.sh >/dev/null 2>&1" >> /tmp/current_cron
        crontab /tmp/current_cron
        rm /tmp/current_cron

        echo "✓ SSL certificate auto-renewal configured"
        echo "✓ Nightscout is now running with HTTPS on [[DOMAIN]]"
    else
        echo "✗ Failed to obtain SSL certificate for [[DOMAIN]]"
        echo "Starting Nightscout without SSL..."
        systemctl start nightscout.service
    fi
else
    echo "✗ Domain [[DOMAIN]] does not point to this server yet"
    echo "   Domain resolves to: $DOMAIN_IP"
    echo "   Server IP is: $SERVER_IP"
    echo "   Please update your DNS settings to point [[DOMAIN]] to $SERVER_IP"
    echo "   Then run this script again: sudo /opt/nightscout/scripts/setup_ssl.sh"
    echo "Starting Nightscout without SSL for now..."
    systemctl start nightscout.service
fi
EOL
chmod +x /opt/nightscout/scripts/setup_ssl.sh

echo "SSL setup script created at /opt/nightscout/scripts/setup_ssl.sh"
echo "After pointing your domain to this server, run: sudo /opt/nightscout/scripts/setup_ssl.sh"