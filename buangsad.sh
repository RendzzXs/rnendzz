#!/bin/bash
# ===================================================
# AUTO FIX DB 1698 + WEB RUNNING NORMAL
# ===================================================

set -e

# --- Konfigurasi ---
DOMAIN="www.rendzzclouds.my.id"
WEB_ROOT=""            # Akan auto-detect
DB_USER="root"
DB_PASS="root"         # Password baru yang diinginkan
DB_HOST="127.0.0.1"
DB_NAME="rendzzclouds" # Akan auto-detect dari .env kalau ada

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "${BLUE}=== AUTO FIX DB 1698 + WEB NORMAL ===${NC}"

# ===================================================
# 1. DETEKSI ENGINE DB
# ===================================================
if command -v mariadb >/dev/null 2>&1 && systemctl is-active --quiet mariadb; then
    ENGINE="MariaDB"
elif systemctl is-active --quiet mysql; then
    ENGINE="MySQL"
else
    ENGINE="MySQL"
fi
echo -e "${YELLOW}🔎 Engine DB: ${ENGINE}${NC}"

# ===================================================
# 2. FIX USER DB (Auto-detect sintaks)
# ===================================================
echo -e "${YELLOW}🔧 Memperbaiki autentikasi user '${DB_USER}'...${NC}"

if [ "$ENGINE" == "MariaDB" ]; then
    mariadb <<EOF 2>/dev/null || true
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('${DB_PASS}');
FLUSH PRIVILEGES;
EOF
else
    mysql <<EOF 2>/dev/null || true
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASS}';
FLUSH PRIVILEGES;
EOF
fi

# ===================================================
# 3. AUTO-DETECT WEB ROOT & FRAMEWORK
# ===================================================
echo -e "${YELLOW}🔎 Mencari document root aplikasi...${NC}"

# Cari via nginx config
if [ -d /etc/nginx/sites-enabled ]; then
    WEB_ROOT=$(grep -rh "root " /etc/nginx/sites-enabled/ 2>/dev/null | grep -v "#" | awk '{print $2}' | tr -d ';' | head -1)
fi

# Cari via apache config
if [ -z "$WEB_ROOT" ] && [ -d /etc/apache2/sites-enabled ]; then
    WEB_ROOT=$(grep -rh "DocumentRoot" /etc/apache2/sites-enabled/ 2>/dev/null | awk '{print $2}' | tr -d '"' | head -1)
fi

# Fallback ke default common paths
if [ -z "$WEB_ROOT" ] || [ ! -d "$WEB_ROOT" ]; then
    for p in /var/www/html /var/www/rendzzclouds /var/www/$DOMAIN /var/www; do
        if [ -f "$p/artisan" ] || [ -f "$p/wp-config.php" ] || [ -f "$p/index.php" ]; then
            WEB_ROOT="$p"
            break
        fi
    done
fi

if [ -z "$WEB_ROOT" ]; then
    echo -e "${RED}❌ Document root tidak ditemukan. Lewati update web config.${NC}"
else
    echo -e "${GREEN}✅ Web root: ${WEB_ROOT}${NC}"
fi

# ===================================================
# 4. AUTO-UPDATE CONFIG APLIKASI
# ===================================================
if [ -n "$WEB_ROOT" ]; then
    # --- Laravel ---
    if [ -f "$WEB_ROOT/.env" ]; then
        echo -e "${YELLOW}📝 Update .env (Laravel)...${NC}"
        # Ambil DB_NAME dari .env kalau ada
        EXISTING_DB=$(grep -E "^DB_DATABASE=" "$WEB_ROOT/.env" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        [ -n "$EXISTING_DB" ] && DB_NAME="$EXISTING_DB"

        sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=mysql/" "$WEB_ROOT/.env"
        sed -i "s/^DB_HOST=.*/DB_HOST=${DB_HOST}/" "$WEB_ROOT/.env"
        sed -i "s/^DB_PORT=.*/DB_PORT=3306/" "$WEB_ROOT/.env"
        sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" "$WEB_ROOT/.env"
        sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USER}/" "$WEB_ROOT/.env"
        sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASS}/" "$WEB_ROOT/.env"

        # Kalau .env tidak punya baris2 tsb, tambahkan
        for kv in "DB_CONNECTION=mysql" "DB_HOST=${DB_HOST}" "DB_PORT=3306" "DB_DATABASE=${DB_NAME}" "DB_USERNAME=${DB_USER}" "DB_PASSWORD=${DB_PASS}"; do
            key="${kv%%=*}"
            grep -q "^${key}=" "$WEB_ROOT/.env" || echo "$kv" >> "$WEB_ROOT/.env"
        done

        # Clear cache Laravel
        if [ -f "$WEB_ROOT/artisan" ]; then
            echo -e "${YELLOW}🧹 Membersihkan cache Laravel...${NC}"
            cd "$WEB_ROOT"
            php artisan config:clear 2>/dev/null || true
            php artisan cache:clear 2>/dev/null || true
            php artisan view:clear 2>/dev/null || true
            chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true
            chmod -R 775 storage bootstrap/cache 2>/dev/null || true
            cd - >/dev/null
        fi

    # --- WordPress ---
    elif [ -f "$WEB_ROOT/wp-config.php" ]; then
        echo -e "${YELLOW}📝 Update wp-config.php (WordPress)...${NC}"
        sed -i "s/define( *'DB_USER' *, *'[^']*' *);/define('DB_USER', '${DB_USER}');/" "$WEB_ROOT/wp-config.php"
        sed -i "s/define( *'DB_PASSWORD' *, *'[^']*' *);/define('DB_PASSWORD', '${DB_PASS}');/" "$WEB_ROOT/wp-config.php"
        sed -i "s/define( *'DB_HOST' *, *'[^']*' *);/define('DB_HOST', '${DB_HOST}');/" "$WEB_ROOT/wp-config.php"
    fi
fi

# ===================================================
# 5. PASTIKAN DATABASE ADA
# ===================================================
echo -e "${YELLOW}🔍 Cek database '${DB_NAME}'...${NC}"
if mysql -u"${DB_USER}" -p"${DB_PASS}" -h"${DB_HOST}" -e "USE ${DB_NAME};" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Database ada.${NC}"
else
    echo -e "${YELLOW}⚠️  Database belum ada, membuat...${NC}"
    mysql -u"${DB_USER}" -p"${DB_PASS}" -h"${DB_HOST}" -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;" || true
fi

# ===================================================
# 6. RESTART WEB SERVER + PHP-FPM
# ===================================================
echo -e "${YELLOW}♻️  Restart web server & PHP-FPM...${NC}"

if systemctl is-active --quiet nginx; then
    systemctl restart nginx && echo -e "${GREEN}✅ Nginx restarted${NC}"
fi

if systemctl is-active --quiet apache2; then
    systemctl restart apache2 && echo -e "${GREEN}✅ Apache restarted${NC}"
fi

# Restart semua versi PHP-FPM yang aktif
PHP_SVCS=$(systemctl list-units --type=service --state=running | grep -oE 'php[0-9.]+-fpm' | sort -u)
for svc in $PHP_SVCS; do
    systemctl restart "$svc" && echo -e "${GREEN}✅ ${svc} restarted${NC}"
done

# ===================================================
# 7. TEST WEB RESPONSE
# ===================================================
echo -e "${YELLOW}🌐 Test akses web http://${DOMAIN} ...${NC}"
sleep 2

# Test via localhost dulu (bypass DNS)
LOCAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: ${DOMAIN}" http://127.0.0.1/ || echo "000")
echo -e "   ↳ Local HTTP code: ${LOCAL_CODE}"

# Test via domain publik
PUBLIC_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://${DOMAIN}/" || echo "000")
echo -e "   ↳ Public HTTPS code: ${PUBLIC_CODE}"

echo ""
if [[ "$LOCAL_CODE" == "200" || "$LOCAL_CODE" == "301" || "$LOCAL_CODE" == "302" ]] && \
   [[ "$PUBLIC_CODE" == "200" || "$PUBLIC_CODE" == "301" || "$PUBLIC_CODE" == "302" ]]; then
    echo -e "${GREEN}🎉 WEB SUDAH NORMAL!${NC}"
else
    echo -e "${RED}⚠️  Web belum normal sepenuhnya.${NC}"
    echo -e "   Cek log: tail -f /var/log/nginx/error.log  atau  /var/log/apache2/error.log"
    echo -e "   Cek PHP: journalctl -u php*-fpm -n 50"
fi

echo ""
echo -e "${BLUE}=== RINGKASAN KREDENSIAL ===${NC}"
echo "   DB_HOST     = ${DB_HOST}"
echo "   DB_NAME     = ${DB_NAME}"
echo "   DB_USERNAME = ${DB_USER}"
echo "   DB_PASSWORD = ${DB_PASS}"
echo "   WEB_ROOT    = ${WEB_ROOT:-'(tidak terdeteksi)'}"
