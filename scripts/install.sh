#!/usr/bin/env bash
# Instalasi Forgejo dari nol pada Ubuntu 22.04/24.04.
# Pemakaian: ./install.sh git.contoh.com admin@contoh.com
# Jalankan sebagai user biasa yang punya sudo (bukan root).
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Pemakaian: $0 <domain> <email>"
  exit 1
fi

DOMAIN="$1"
EMAIL="$2"
DB_PASS="$(openssl rand -hex 16)"
WORKDIR="$HOME/forgejo"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

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
cp "$REPO_DIR/docker-compose.yml" "$WORKDIR/docker-compose.yml"
cat > "$WORKDIR/.env" <<ENV
DOMAIN=$DOMAIN
POSTGRES_PASSWORD=$DB_PASS
ENV
chmod 600 "$WORKDIR/.env"

echo "==> Menjalankan Forgejo"
cd "$WORKDIR"
sudo docker compose up -d

echo "==> Konfigurasi Nginx"
sed "s/git.contoh.com/$DOMAIN/g" "$REPO_DIR/nginx/forgejo.conf" | sudo tee /etc/nginx/sites-available/forgejo >/dev/null
sudo ln -sf /etc/nginx/sites-available/forgejo /etc/nginx/sites-enabled/forgejo
sudo nginx -t
sudo systemctl reload nginx

echo "==> Mengaktifkan HTTPS"
sudo certbot --nginx -d "$DOMAIN" -m "$EMAIL" --agree-tos --non-interactive --redirect

echo
echo "Selesai. Buka https://$DOMAIN untuk membuat akun admin."
echo "Password database tersimpan di $WORKDIR/.env (jangan dibagikan)."
