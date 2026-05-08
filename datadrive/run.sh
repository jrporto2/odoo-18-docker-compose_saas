#!/bin/bash
set -x
#curl -s https://raw.githubusercontent.com/jrporto2/odoo-18-docker-compose_saas/refs/heads/main/datadrive/run.sh | sudo bash -s odoo-saas 10017 20017 password
#curl -fsSL https://raw.githubusercontent.com/jrporto2/odoo-18-docker-compose_saas/main/datadrive/run.sh | sudo bash -s odoo-saas 10017 20017 password
DESTINATION=$1
PORT=$2
CHAT=$3
MASTERPASSWORD=${4:-adminpasswd}
BASE=$(pwd)
#clear directory
rm -rf $DESTINATION
# Clone Odoo directory
git clone --depth=1 https://github.com/jrporto2/odoo-18-docker-compose_saas.git $DESTINATION
rm -rf $DESTINATION/.git
sudo chown -R 5050:5050 $DESTINATION/datadrive/pgadmin
sudo chmod -R 700 $DESTINATION/datadrive/pgadmin
# chmod +x $DESTINATION/datadrive/admin/scripts/create-client.sh
# Run Odoo
docker compose -f $DESTINATION/datadrive/core/docker-compose.yml up -d
echo "Odoo started at http://localhost:$PORT | Master Password: $MASTERPASSWORD | Live chat port: $CHAT"
sed -i 's|DESTINATION|'$BASE/$DESTINATION'|g' $DESTINATION/datadrive/admin/scripts/create-client.sh 
sudo chmod -R 750 $DESTINATION/datadrive/admin/scripts/create-client.sh
#cd ~/odoo-saas/datadrive/templates
#sudo ln ~/odoo-saas/datadrive/core/.env .env


