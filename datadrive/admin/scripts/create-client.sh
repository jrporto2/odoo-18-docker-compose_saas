#!/bin/bash
set -e

CLIENT="$1"

if [[ ! "$CLIENT" =~ ^[a-z0-9_]{3,20}$ ]]; then
  echo "Nombre de cliente inválido"
  exit 1
fi

BASE="DESTINATION/datadrive/clients"
TEMPLATE="DESTINATION/datadrive/templates/client"
NGINX_DIR="DESTINATION/datadrive/nginx"

echo "➡️ Creando cliente: $CLIENT"

# 1. Crear estructura
mkdir -p "$BASE/$CLIENT"
cp -r "$TEMPLATE/"* "$BASE/$CLIENT/"

# 2. Reemplazar placeholders
sed -i "s/CLIENT_NAME/$CLIENT/g" \
  "$BASE/$CLIENT/docker-compose.yml"

# 3. Crear base de datos e inicializar Odoo
docker exec c_postgres createdb -U odoo "$CLIENT"

docker exec c_odoo \
  odoo \
  -d "$CLIENT" \
  -i base \
  --without-demo=all \
  --stop-after-init

# 4. Levantar contenedor del cliente
docker compose -f "$BASE/$CLIENT/docker-compose.yml" up -d

# 5. Crear config NGINX
cat > "$NGINX_DIR/$CLIENT.conf" <<EOF
server {
    server_name $CLIENT.midominio.com;

    location / {
        proxy_pass http://c_odoo_$CLIENT:8069;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# 6. Recargar NGINX
docker restart c_nginx

echo "✅ Cliente $CLIENT creado correctamente"
