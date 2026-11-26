
#!/bin/bash
# ==================================================
# RENDZZ CLOUDS | AUTO WEB & DATABASE REPAIR
# Domain: rendzzclouds.my.id
# ==================================================

set -Eeuo pipefail

DOMAIN="rendzzclouds.my.id"
WWW="www.rendzzclouds.my.id"
BACKUP="/root/rendzz-repair-backup-$(date +%Y%m%d-%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[ SUCCESS ]${NC} $1"; }
warn() { echo -e "${YELLOW}[ WARNING ]${NC} $1"; }
err()  { echo -e "${RED}[ ERROR ]${NC} $1"; }

clear
echo "=========================================="
echo "       RENDZZ CLOUDS AUTO REPAIR"
echo "=========================================="

if [ "$EUID" -ne 0 ]; then
    err "Jalankan menggunakan root!"
    exit 1
fi

mkdir -p "$BACKUP"

echo
echo "[1/8] Checking system..."

command -v mysql >/dev/null || {
    err "MySQL/MariaDB client tidak ditemukan."
    exit 1
}

command -v python3 >/dev/null || {
    err "Python3 tidak ditemukan."
    exit 1
}

ok "System requirements detected"

echo
echo "[2/8] Checking database..."

if systemctl is-active --quiet mariadb; then
    DB_SERVICE="mariadb"
elif systemctl is-active --quiet mysql; then
    DB_SERVICE="mysql"
else
    err "MySQL/MariaDB tidak berjalan."
    exit 1
fi

ok "$DB_SERVICE aktif"

echo
echo "[3/8] Database configuration"

read -rp "Database name: " DB_NAME
read -rp "Database username baru: " DB_USER
read -rsp "Database password baru: " DB_PASS
echo

if [[ ! "$DB_NAME" =~ ^[a-zA-Z0-9_]+$ ]] ||
   [[ ! "$DB_USER" =~ ^[a-zA-Z0-9_]+$ ]] ||
   [ -z "$DB_PASS" ]; then
    err "Nama database/user tidak valid atau password kosong."
    exit 1
fi

if [ "$DB_USER" = "root" ]; then
    err "Gunakan username khusus website, bukan root."
    exit 1
fi

echo
echo "[4/8] Connecting MySQL..."

if ! mysql -e "SELECT 1" >/dev/null 2>&1; then
    err "Tidak bisa login melalui sudo/root MySQL."
    echo "Perlu akses administrator database untuk melanjutkan."
    exit 1
fi

SQL_PASS=$(python3 -c \
'import sys; print(sys.argv[1].replace("\\","\\\\").replace("'","\\'"))' \
"$DB_PASS")

mysql <<SQL
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost'
IDENTIFIED BY '${SQL_PASS}';

ALTER USER '${DB_USER}'@'localhost'
IDENTIFIED BY '${SQL_PASS}';

GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.*
TO '${DB_USER}'@'localhost';

FLUSH PRIVILEGES;
SQL

unset SQL_PASS

ok "Database user configured"

echo
echo "[5/8] Finding website configuration..."

APP_DIR=""

for DIR in /var/www/html /var/www/"$DOMAIN" /var/www; do
    if [ -f "$DIR/.env" ]; then
        APP_DIR="$DIR"
        break
    fi
done

if [ -z "$APP_DIR" ]; then
    warn "File .env tidak ditemukan otomatis."
    read -rp "Masukkan lokasi folder website: " APP_DIR
fi

if [ ! -d "$APP_DIR" ]; then
    err "Folder website tidak ditemukan: $APP_DIR"
    exit 1
fi

if [ ! -f "$APP_DIR/.env" ]; then
    err "Tidak ada .env di $APP_DIR."
    echo "Bash tidak akan membuat konfigurasi aplikasi palsu."
    echo "Kirim config.php atau index.php agar bisa diperbaiki."
    exit 1
fi

cp -a "$APP_DIR/.env" "$BACKUP/env.backup"

echo
echo "[6/8] Updating Laravel environment..."

export DB_NAME DB_USER DB_PASS DOMAIN

python3 <<'PY'
import os
from pathlib import Path

p = Path(os.environ["APP_DIR"]) if "APP_DIR" in os.environ else None
if p is None:
    raise SystemExit("APP_DIR missing")
PY
