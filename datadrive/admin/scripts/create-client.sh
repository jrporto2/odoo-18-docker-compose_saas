#!/bin/bash
set -x
set -e
CLIENT="$1"

if [[ ! "$CLIENT" =~ ^[a-z0-9_]{3,20}$ ]]; then
  echo "Nombre de cliente inválido"
  exit 1
fi

BASE="DESTINATION/datadrive/clients"
TEMPLATE="DESTINATION/datadrive/templates/client"
NGINX_DIR="DESTINATION/datadrive/nginx"

echo "➡️ Creando cliente SaaS: $CLIENT"

# 1. Crear estructura
mkdir -p "$BASE/$CLIENT"
cp -r "$TEMPLATE/"* "$BASE/$CLIENT/"
ln -s ~/odoo-saas/datadrive/core/.env "$BASE/$CLIENT"/.env
chown -R 100:101 "$BASE/$CLIENT"
chmod -R 755 "$BASE/$CLIENT"

# 2. Reemplazar placeholders
sed -i "s/CLIENT_NAME/$CLIENT/g" \
  "$BASE/$CLIENT/docker-compose.yml"
sed -i "s/CLIENT_NAME/$CLIENT/g" \
  "$BASE/$CLIENT/odoo.conf"
# 3. Crear base de datos e inicializar Odoo
docker exec c_pgsaas createdb -U odoo "$CLIENT"

#  4. Levantar contenedor Odoo del cliente
docker compose -f "$BASE/$CLIENT/docker-compose.yml" up -d
echo "⏳ Esperando a que el contenedor arranque..."
sleep 10

#  5 .Inicializar base de datos

docker exec c_odoo_"$CLIENT" odoo \
  -d "$CLIENT" \
  -i base \
  --without-demo=all \
  --stop-after-init

# 6. Crear config NGINX
cat > "$NGINX_DIR/conf.d/$CLIENT.conf" <<'EOF'
# HTTP -> HTTPS
server {
    listen 80;
    server_name  CLIENT.multipath.net.pe;
    return 301 https://$host$request_uri;
}

# HTTPS
server {
    listen 443 ssl;
    server_name CLIENT.multipath.net.pe;

    ssl_certificate     /etc/nginx/ssl/CLIENT.multipath.net.pe.crt;
    ssl_certificate_key /etc/nginx/ssl/CLIENT.multipath.net.pe.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    resolver 127.0.0.11 valid=30s;
    set $upstream c_odoo_CLIENT;
    location / {
        proxy_pass http://$upstream:8069;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

EOF
sed -i "s/CLIENT/$CLIENT/g" "$NGINX_DIR/conf.d/$CLIENT.conf"
sudo scp /etc/ssl/certs/origin_certificate.pem DESTINATION/datadrive/nginx/certs/$CLIENT.multipath.net.pe.crt
sudo scp /etc/ssl/certs/origin_private_key.pem DESTINATION/datadrive/nginx/certs/$CLIENT.multipath.net.pe.key
sudo chmod 600 DESTINATION/datadrive/nginx/certs/*.key
sudo chmod 644 DESTINATION/datadrive/nginx/certs/*.crt
# 6. Recargar NGINX
docker restart c_nginxsaas

echo "✅ Cliente SaaS $CLIENT creado correctamente"
