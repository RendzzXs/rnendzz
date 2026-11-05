#!/bin/bash
# ============================================
#   🗑️ RENDZZ WEB UNINSTALLER
#   Hapus Semua Web, Database & Config
# ============================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}❌ Harus root!${NC}"; exit 1; }

clear
echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
echo -e "${RED}║  🗑️ RENDZZ WEB UNINSTALLER                 ║${NC}"
echo -e "${RED}║  Semua Web & Database akan DIHAPUS!        ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
echo ""

# ============ KONFIRMASI ============
echo -e "${YELLOW}Script ini bakal ngehapus:${NC}"
echo -e "  • Semua folder web di /var/www/"
echo -e "  • Semua Database MySQL (kecuali sistem)"
echo -e "  • Semua config Nginx (sites-enabled & sites-available)"
echo -e "  • Semua file SSL (Let's Encrypt)"
echo ""
echo -e "${RED}⚠️  TINDAKAN INI TIDAK BISA DIBATALKAN!${NC}"
echo ""
read -p "Ketik 'HAPUS' (huruf kapital) untuk melanjutkan: " CONFIRM

if [[ "$CONFIRM" != "HAPUS" ]]; then
    echo -e "${YELLOW}Dibatalkan.${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}[1/6] Menghapus semua folder web...${NC}"
# Hapus folder web
find /var/www -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} + 2>/dev/null
# Hapus file web (misal index.html)
find /var/www -mindepth 1 -maxdepth 1 -type f -exec rm -f {} + 2>/dev/null
echo -e "${GREEN}  ✅ Folder /var/www/ dibersihkan${NC}"

echo -e "${CYAN}[2/6] Menghapus semua database user...${NC}"
# Ambil semua database, kecuali yang sistem
DBS=$(mysql -u root -N -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "^(information_schema|mysql|performance_schema|sys)$")

if [ -n "$DBS" ]; then
    for DB in $DBS; do
        mysql -u root -e "DROP DATABASE \`$DB\`;" 2>/dev/null
        echo -e "  🗑️ Drop DB: $DB"
    done
else
    echo -e "  ℹ️  Tidak ada database user."
fi

# Hapus semua user MySQL custom (kecuali root & sistem)
USERS=$(mysql -u root -N -e "SELECT user FROM mysql.user WHERE user NOT IN ('root','mysql.sys','mysql.session','mysql.infoschema','debian-sys-maint');" 2>/dev/null)
if [ -n "$USERS" ]; then
    for USR in $USERS; do
        mysql -u root -e "DROP USER '$USR'@'localhost';" 2>/dev/null
        mysql -u root -e "DROP USER '$USR'@'127.0.0.1';" 2>/dev/null
        mysql -u root -e "DROP USER '$USR'@'%';" 2>/dev/null
        echo -e "  🗑️ Drop User: $USR"
    done
    mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null
fi
echo -e "${GREEN}  ✅ Database bersih${NC}"

echo -e "${CYAN}[3/6] Menghapus config Nginx...${NC}"
rm -rf /etc/nginx/sites-enabled/* 2>/dev/null
rm -rf /etc/nginx/sites-available/* 2>/dev/null
rm -rf /etc/nginx/conf.d/* 2>/dev/null
echo -e "${GREEN}  ✅ Config Nginx bersih${NC}"

echo -e "${CYAN}[4/6] Menghapus SSL Certbot...${NC}"
rm -rf /etc/letsencrypt/live/* 2>/dev/null
rm -rf /etc/letsencrypt/renewal/* 2>/dev/null
rm -rf /etc/letsencrypt/archive/* 2>/dev/null
echo -e "${GREEN}  ✅ SSL Certbot dibersihkan${NC}"

echo -e "${CYAN}[5/6] Ngebersihin sisa file & log...${NC}"
# Hapus log nginx
rm -rf /var/log/nginx/*.log 2>/dev/null
# Hapus log php
rm -rf /var/log/php*.log 2>/dev/null
# Hapus folder backup
rm -rf /var/www/backup_* 2>/dev/null
echo -e "${GREEN}  ✅ File & log dibersihkan${NC}"

echo -e "${CYAN}[6/6] Restart Service...${NC}"
systemctl reload nginx 2>/dev/null
systemctl restart php8.3-fpm 2>/dev/null
echo -e "${GREEN}  ✅ Service di-restart${NC}"

# ============ SELESAI ============
clear
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ SEMUA WEB BERHASIL DIHAPUS!             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📊 Storage VPS:${NC}"
df -h / | tail -1 | awk '{print "  Used: "$3" | Free: "$4" | Use%: "$5}'
echo ""
echo -e "${CYAN}📁 Sisa folder di /var/www:${NC}"
ls -la /var/www/ 2>/dev/null || echo "  (Kosong)"
echo ""
echo -e "${CYAN}🗄️  Sisa database:${NC}"
mysql -u root -N -e "SHOW DATABASES;" 2>/dev/null | awk '{print "  - " $1}'
echo ""
echo -e "${YELLOW}💡 VPS siap buat install web baru!${NC}"
