services:
  caddy:
    image: caddy:2-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    restart: unless-stopped
    depends_on:
      - nightscout

  nightscout:
    image: nightscout/cgm-remote-monitor:latest
    environment:
      - PORT=1337
      - TRUST_PROXY=true
      - INSECURE_USE_HTTP=true
    env_file:
      - .env
    restart: unless-stopped
    volumes:
      - ./data:/var/opt/nightscout

volumes:
  caddy_data:
  caddy_config:
  nightscout_data: