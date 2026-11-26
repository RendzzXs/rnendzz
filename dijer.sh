#!/bin/bash

# ============================================
# VPS Web Stack Uninstaller
# Skip Pterodactyl
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Cek root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[✗] Script harus dijalankan sebagai root!${NC}"
   exit 1
fi

# Cek Pterodactyl
check_pterodactyl() {
    if [ -d "/var/www/pterodactyl" ] || [ -d "/var/www/ptero" ] || systemctl list-units --type=service | grep -q "pteroq"; then
        echo -e "${RED}[!] Pterodactyl terdeteksi di VPS ini!${NC}"
        echo -e "${YELLOW}[!] Script ini akan SKIP semua komponen Pterodactyl.${NC}"
        echo ""
        PTERO_EXISTS=true
    else
        PTERO_EXISTS=false
    fi
}

# ============================================
# FUNGSI UNINSTALL
# ============================================

uninstall_nginx() {
    echo -e "${BLUE}[*] Uninstalling Nginx...${NC}"
    systemctl stop nginx 2>/dev/null
    systemctl disable nginx 2>/dev/null
    apt-get purge -y nginx nginx-common nginx-full 2>/dev/null
    apt-get autoremove -y 2>/dev/null
    rm -rf /etc/nginx /var/log/nginx /var/www/html 2>/dev/null
    echo -e "${GREEN}[✓] Nginx dihapus${NC}"
}

uninstall_apache() {
    echo -e "${BLUE}[*] Uninstalling Apache...${NC}"
    systemctl stop apache2 2>/dev/null
    systemctl disable apache2 2>/dev/null
    apt-get purge -y apache2 apache2-utils apache2-bin apache2-data 2>/dev/null
    apt-get autoremove -y 2>/dev/null
    rm -rf /etc/apache2 /var/log/apache2 /var/www/html 2>/dev/null
    echo -e "${GREEN}[✓] Apache dihapus${NC}"
}

uninstall_php() {
    echo -e "${BLUE}[*] Uninstalling PHP...${NC}"
    # Deteksi versi PHP
    PHP_VERSIONS=$(ls /etc/php 2>/dev/null)
    for ver in $PHP_VERSIONS; do
        systemctl stop php${ver}-fpm 2>/dev/null
        systemctl disable php${ver}-fpm 2>/dev/null
    done
    apt-get purge -y 'php*' 2>/dev/null
    apt-get autoremove -y 2>/dev/null
    rm -rf /etc/php /var/log/php* /var/lib/php 2>/dev/null
    echo -e "${GREEN}[✓] PHP dihapus${NC}"
}

uninstall_mysql() {
    echo -e "${BLUE}[*] Uninstalling MySQL/MariaDB...${NC}"
    systemctl stop mysql 2>/dev/null
    systemctl stop mariadb 2>/dev/null
    systemctl disable mysql 2>/dev/null
    systemctl disable mariadb 2>/dev/null
    apt-get purge -y mysql-server mysql-client mysql-common mariadb-server mariadb-client 2>/dev/null
    apt-get autoremove -y 2>/dev/null
    rm -rf /etc/mysql /var/lib/mysql /var/log/mysql 2>/dev/null
    echo -e "${GREEN}[✓] MySQL/MariaDB dihapus${NC}"
}

uninstall_redis() {
    echo -e "${BLUE}[*] Uninstalling Redis...${NC}"
    systemctl stop redis-server 2>/dev/null
    systemctl disable redis-server 2>/dev/null
    apt-get purge -y redis-server redis-tools 2>/dev/null
    apt-get autoremove -y 2>/dev/null
    rm -rf /etc/redis /var/lib/redis /var/log/redis 2>/dev/null
    echo -e "${GREEN}[✓] Redis dihapus${NC}"
}

uninstall_certbot() {
    echo -e "${BLUE}[*] Uninstalling Certbot...${NC}"
    apt-get purge -y certbot python3-certbot-nginx python3-certbot-apache 2>/dev/null
    apt-get autoremove -y 2>/dev/null
    rm -rf /etc/letsencrypt /var/lib/letsencrypt /var/log/letsencrypt 2>/dev/null
    echo -e "${GREEN}[✓] Certbot dihapus${NC}"
}

uninstall_nodejs() {
    echo -e "${BLUE}[*] Uninstalling Node.js & NPM...${NC}"
    apt-get purge -y nodejs npm 2>/dev/null
    apt-get autoremove -y 2>/dev/null
    rm -rf /usr/lib/node_modules /usr/local/lib/node_modules /root/.npm /root/.node 2>/dev/null
    echo -e "${GREEN}[✓] Node.js dihapus${NC}"
}

uninstall_docker() {
    if [ "$PTERO_EXISTS" = true ]; then
        echo -e "${YELLOW}[!] Docker terdeteksi — tapi SKIP karena mungkin dipakai Pterodactyl${NC}"
        return
    fi
    echo -e "${BLUE}[*] Uninstalling Docker...${NC}"
    systemctl stop docker 2>/dev/null
    systemctl disable docker 2>/dev/null
    apt-get purge -y docker-ce docker-ce-cli containerd.io docker.io docker-compose-plugin 2>/dev/null
    apt-get autoremove -y 2>/dev/null
    rm -rf /var/lib/docker /etc/docker /var/lib/containerd 2>/dev/null
    echo -e "${GREEN}[✓] Docker dihapus${NC}"
}

uninstall_composer() {
    echo -e "${BLUE}[*] Uninstalling Composer...${NC}"
    rm -f /usr/local/bin/composer /usr/bin/composer
    rm -rf /root/.composer /root/.config/composer
    echo -e "${GREEN}[✓] Composer dihapus${NC}"
}

uninstall_phpmyadmin() {
    if [ -d "/usr/share/phpmyadmin" ] || [ -d "/var/www/phpmyadmin" ]; then
        echo -e "${BLUE}[*] Uninstalling phpMyAdmin...${NC}"
        rm -rf /usr/share/phpmyadmin /var/www/phpmyadmin /etc/phpmyadmin
        echo -e "${GREEN}[✓] phpMyAdmin dihapus${NC}"
    fi
}

cleanup_web_files() {
    echo -e "${BLUE}[*] Membersihkan file web...${NC}"
    # HATI-HATI: skip jika Pterodactyl ada
    if [ "$PTERO_EXISTS" = true ]; then
        echo -e "${YELLOW}[!] SKIP hapus /var/www karena Pterodactyl ada${NC}"
        return
    fi
    rm -rf /var/www/* 2>/dev/null
    rm -rf /tmp/* 2>/dev/null
    echo -e "${GREEN}[✓] File web dibersihkan${NC}"
}

cleanup_logs() {
    echo -e "${BLUE}[*] Membersihkan log...${NC}"
    journalctl --vacuum-time=1s 2>/dev/null
    rm -rf /var/log/nginx/* /var/log/apache2/* 2>/dev/null
    echo -e "${GREEN}[✓] Log dibersihkan${NC}"
}

# ============================================
# MENU INTERAKTIF
# ============================================

show_menu() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     VPS Web Stack Uninstaller            ║${NC}"
    echo -e "${BLUE}║     (Pterodactyl akan di-SKIP)           ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo "  1) Uninstall Nginx"
    echo "  2) Uninstall Apache"
    echo "  3) Uninstall PHP"
    echo "  4) Uninstall MySQL/MariaDB"
    echo "  5) Uninstall Redis"
    echo "  6) Uninstall Certbot/SSL"
    echo "  7) Uninstall Node.js & NPM"
    echo "  8) Uninstall Docker (skip jika Ptero)"
    echo "  9) Uninstall Composer"
    echo " 10) Uninstall phpMyAdmin"
    echo " 11) Bersihkan File Web (/var/www)"
    echo " 12) Bersihkan Log"
    echo ""
    echo -e "${RED} 99) UNINSTALL SEMUA (kecuali Pterodactyl)${NC}"
    echo "  0) Keluar"
    echo ""
    read -p "Pilih opsi [0-99]: " choice

    case $choice in
        1) uninstall_nginx ;;
        2) uninstall_apache ;;
        3) uninstall_php ;;
        4) uninstall_mysql ;;
        5) uninstall_redis ;;
        6) uninstall_certbot ;;
        7) uninstall_nodejs ;;
        8) uninstall_docker ;;
        9) uninstall_composer ;;
        10) uninstall_phpmyadmin ;;
        11) cleanup_web_files ;;
        12) cleanup_logs ;;
        99) uninstall_all ;;
        0) exit 0 ;;
        *) echo -e "${RED}[✗] Pilihan tidak valid${NC}" ;;
    esac
}

uninstall_all() {
    echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   WARNING: UNINSTALL SEMUA WEB STACK     ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Yakin ingin uninstall SEMUA? (ketik 'YES'): " confirm
    if [ "$confirm" != "YES" ]; then
        echo -e "${YELLOW}[!] Dibatalkan${NC}"
        return
    fi

    uninstall_nginx
    uninstall_apache
    uninstall_php
    uninstall_mysql
    uninstall_redis
    uninstall_certbot
    uninstall_nodejs
    uninstall_docker
    uninstall_composer
    uninstall_phpmyadmin
    cleanup_web_files
    cleanup_logs

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✓ Semua web stack berhasil dihapus     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
}

# ============================================
# MAIN
# ============================================

check_pterodactyl

while true; do
    show_menu
    echo ""
    read -p "Tekan ENTER untuk lanjut..."
done
