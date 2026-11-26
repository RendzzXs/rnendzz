#!/bin/bash
# ==========================================
# 🛠️ AUTO FIX: DB Access Denied & Panel Restart
# ==========================================

DOMAIN="www.rendzzclouds.my.id" # GANTI kalau domain lu beda
WEB_ROOT="/var/www/$DOMAIN"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}🛠️  Memulai perbaikan database & panel...${NC}"

# 1. Fix MySQL Root Access (Kalau lu butuh MySQL buat hal lain)
echo -e "${CYAN}[1/3] Memperbaiki akses MySQL Root (opsional)...${NC}"
if command -v mysql >/dev/null 2>&1; then
    # Set root pakai mysql_native_password (biar bisa login pake password)
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root'; FLUSH PRIVILEGES;" 2>/dev/null || true
    echo -e "${GREEN}  ✓ MySQL Root fixed (password: root)${NC}"
else
    echo -e "${YELLOW}  ⚠️ MySQL tidak terinstall, lanjut ke panel...${NC}"
fi

# 2. Pastikan Web Panel pakai SQLite (Bukan MySQL)
echo -e "${CYAN}[2/3] Memastikan Web Panel pakai SQLite...${NC}"
cd "$WEB_ROOT" || { echo -e "${RED}❌ Folder web tidak ada!${NC}"; exit 1; }

# Hapus konfigurasi database lama jika ada yang nyangkut
rm -f .env 2>/dev/null
cat > .env << ENVEOF
PORT=3000
DOMAIN=$DOMAIN
SESSION_SECRET=$(openssl rand -hex 32)
ENVEOF
chmod 600 .env

# Pastikan SQLite file aman
if [ ! -f "panel.db" ]; then
    echo -e "${YELLOW}  ⚠️ Database SQLite belum ada, akan dibuat otomatis sama aplikasi.${NC}"
else
    echo -e "${GREEN}  ✓ Database SQLite (panel.db) ditemukan.${NC}"
fi

# 3. Restart PM2 & Nginx
echo -e "${CYAN}[3/3] Restart PM2 & Nginx...${NC}"
pm2 delete webpanel >/dev/null 2>&1
pm2 start app.js --name webpanel >/dev/null 2>&1
pm2 save >/dev/null 2>&1
nginx -t >/dev/null 2>&1 && systemctl reload nginx || echo -e "${RED}  ❌ Nginx error!${NC}"

echo -e "\n${GREEN}✅ PERBAIKAN SELESAI!${NC}"
echo -e "Buka panel lu: ${GREEN}https://$DOMAIN${NC}"
echo -e "Jika lu mau konek MySQL manual, username: ${GREEN}root${NC}, password: ${GREEN}root${NC}"
echo -e ""
echo -e "${CYAN}Cek log error dengan:${NC} pm2 logs webpanel"
