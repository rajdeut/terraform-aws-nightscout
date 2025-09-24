[Unit]
Description=Nightscout Docker Compose
Requires=docker.service
After=docker.service
ConditionPathExists=/opt/nightscout/.env

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/nightscout
ExecStartPre=/bin/sh -c 'if [ ! -f .env ]; then echo "Environment file not found"; exit 1; fi'
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target