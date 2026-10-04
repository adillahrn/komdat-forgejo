#!/usr/bin/env bash
# Instalasi Forgejo (Docker Compose + PostgreSQL + Nginx + HTTPS) pada Ubuntu 22.04/24.04.
# Pemakaian : ./setup.sh <domain> <email>
# Contoh    : ./setup.sh forgejo-kdjk.malaysiawest.cloudapp.azure.com email@contoh.com
# Jalankan sebagai user biasa yang punya sudo (bukan root).
# Prasyarat : domain sudah mengarah ke IP server, port 80, 443, dan 2222 terbuka.
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Pemakaian: $0 <domain> <email>"
  exit 1
fi

DOMAIN="$1"
EMAIL="$2"
WORKDIR="$HOME/forgejo"

if [ -f "$WORKDIR/.env" ]; then
  echo "PERINGATAN: $WORKDIR/.env sudah ada. Skrip ini hanya untuk server BARU."
  echo "Menjalankannya lagi akan membuat password database baru dan merusak koneksi ke database lama."
  echo "Dibatalkan."
  exit 1
fi

DB_PASS="$(openssl rand -hex 16)"

echo "==> Memasang paket dasar"
sudo apt update
sudo apt install -y ca-certificates curl nginx certbot python3-certbot-nginx ufw openssl

echo "==> Memasang Docker"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sudo sh
fi
sudo usermod -aG docker "$USER"

echo "==> Mengatur firewall (UFW)"
sudo ufw allow 22/tcp
sudo ufw allow 80,443/tcp
sudo ufw allow 2222/tcp
sudo ufw --force enable

echo "==> Menyiapkan $WORKDIR"
mkdir -p "$WORKDIR"
cat > "$WORKDIR/.env" <<ENV
DOMAIN=$DOMAIN
POSTGRES_PASSWORD=$DB_PASS
ENV
chmod 600 "$WORKDIR/.env"

cat > "$WORKDIR/docker-compose.yml" <<'EOF'
networks:
  forgejo:
    external: false

services:
  server:
    image: codeberg.org/forgejo/forgejo:15
    container_name: forgejo
    restart: always
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - FORGEJO__database__DB_TYPE=postgres
      - FORGEJO__database__HOST=db:5432
      - FORGEJO__database__NAME=forgejo
      - FORGEJO__database__USER=forgejo
      - FORGEJO__database__PASSWD=${POSTGRES_PASSWORD}
      - FORGEJO__server__DOMAIN=${DOMAIN}
      - FORGEJO__server__ROOT_URL=https://${DOMAIN}/
      - FORGEJO__server__SSH_DOMAIN=${DOMAIN}
      - FORGEJO__server__SSH_PORT=2222
      - FORGEJO__server__SSH_LISTEN_PORT=22
      - FORGEJO__attachment__MAX_SIZE=100
    networks:
      - forgejo
    volumes:
      - ./forgejo:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "127.0.0.1:3000:3000"
      - "2222:22"
    depends_on:
      - db

  db:
    image: postgres:16
    container_name: forgejo-db
    restart: always
    environment:
      - POSTGRES_USER=forgejo
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=forgejo
    networks:
      - forgejo
    volumes:
      - ./postgres:/var/lib/postgresql/data
EOF

echo "==> Menjalankan Forgejo"
cd "$WORKDIR"
sudo docker compose up -d

echo "==> Konfigurasi Nginx"
sudo tee /etc/nginx/sites-available/forgejo >/dev/null <<'EOF'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;

    client_max_body_size 512M;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
sudo sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/" /etc/nginx/sites-available/forgejo
sudo ln -sf /etc/nginx/sites-available/forgejo /etc/nginx/sites-enabled/forgejo
sudo nginx -t
sudo systemctl reload nginx

echo "==> Mengaktifkan HTTPS"
sudo certbot --nginx -d "$DOMAIN" -m "$EMAIL" --agree-tos --non-interactive --redirect

echo
echo "Selesai. Buka https://$DOMAIN untuk membuat akun admin."
echo "Password database tersimpan di $WORKDIR/.env (jangan dibagikan)."
