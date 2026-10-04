#!/usr/bin/env bash
# Backup database PostgreSQL dan data Forgejo.
# Pemakaian manual : ~/scripts/backup.sh
# Jadwal cron      : 0 2 * * 0 /home/azureuser/scripts/backup.sh >> /home/azureuser/backup/backup.log 2>&1
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-$HOME/backup}"
APP_DIR="${APP_DIR:-$HOME/forgejo}"
KEEP_DAYS="${KEEP_DAYS:-30}"
DATE="$(date +%F)"

mkdir -p "$BACKUP_DIR"
cd "$APP_DIR"

docker exec forgejo-db pg_dump -U forgejo forgejo | gzip > "$BACKUP_DIR/forgejo-db-$DATE.sql.gz"
sudo tar czf "$BACKUP_DIR/forgejo-data-$DATE.tar.gz" forgejo

find "$BACKUP_DIR" -type f -mtime +"$KEEP_DAYS" -delete

echo "Backup $DATE selesai di $BACKUP_DIR"
