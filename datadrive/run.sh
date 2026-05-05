#!/bin/bash
set -x
#curl -s https://raw.githubusercontent.com/jrporto2/odoo-18-docker-compose_saas/refs/heads/main/datadrive/run.sh | sudo bash -s odoo-saas 10017 20017 password
DESTINATION=$1
PORT=$2
CHAT=$3
MASTERPASSWORD=${4:-adminpasswd}
#clear directory
rm -rf $DESTINATION
# Clone Odoo directory
git clone --depth=1 https://github.com/jrporto2/odoo-18-docker-compose_saas.git $DESTINATION
rm -rf $DESTINATION/.git
chmod +x $DESTINATION/datadrive/admin/scripts/create-client.sh
# Run Odoo
docker compose -f $DESTINATION/docker-compose.yml up -d

echo "Odoo started at http://localhost:$PORT | Master Password: $MASTERPASSWORD | Live chat port: $CHAT"
