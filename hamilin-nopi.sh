#!/usr/bin/env bash
set -u

if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Jalankan script ini sebagai root (gunakan: sudo bash restore-stack.sh)"
  exit 1
fi

echo "=== [1/5] Perbaiki Direktori Socket & Permission MariaDB ==="
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
if [ -d /var/lib/mysql ]; then
  chown -R mysql:mysql /var/lib/mysql
fi

echo "=== [2/5] Cek & Pulihkan Paket MariaDB + Ekstensi PHP ==="
export DEBIAN_FRONTEND=noninteractive
dpkg --configure -a >/dev/null 2>&1 || true

if ! command -v mariadbd >/dev/null 2>&1 && ! command -v mysqld >/dev/null 2>&1; then
  echo "Binary MariaDB tidak ditemukan, menginstal ulang mariadb-server..."
  apt-get update -y
  apt-get install -y mariadb-server mariadb-client
fi

# Pastikan driver PHP-MySQL tersedia jika PHP terpasang
if command -v php >/dev/null 2>&1; then
  apt-get install -y php-mysql >/dev/null 2>&1 || true
fi

echo "=== [3/5] Aktifkan & Jalankan Service MariaDB ==="
systemctl unmask mariadb >/dev/null 2>&1 || true
systemctl unmask mysql >/dev/null 2>&1 || true
systemctl daemon-reload

systemctl enable mariadb >/dev/null 2>&1 || true
systemctl restart mariadb || systemctl restart mysql

echo "=== [4/5] Jalankan Layanan Pendamping (PHP-FPM, Nginx, Redis, dll) ==="
# Restart semua service PHP-FPM yang terpasang
for svc in $(systemctl list-unit-files 'php*-fpm.service' --no-legend | awk '{print $1}'); do
  systemctl enable "$svc" >/dev/null 2>&1 || true
  systemctl restart "$svc"
  echo "-> $svc : $(systemctl is-active "$svc")"
done

# Restart Redis jika ada
if systemctl list-unit-files 'redis-server.service' --no-legend | grep -q redis-server; then
  systemctl enable redis-server >/dev/null 2>&1 || true
  systemctl restart redis-server
  echo "-> redis-server : $(systemctl is-active redis-server)"
fi

# Cek konfigurasi & restart Nginx jika ada
if systemctl list-unit-files 'nginx.service' --no-legend | grep -q nginx; then
  if nginx -t >/dev/null 2>&1; then
    systemctl enable nginx >/dev/null 2>&1 || true
    systemctl restart nginx
    echo "-> nginx : $(systemctl is-active nginx)"
  else
    echo "[PERINGATAN] Konfigurasi Nginx ada yang error. Jalankan 'nginx -t' untuk cek barisnya."
  fi
fi

# Restart Pterodactyl Wings jika terpasang
if systemctl list-unit-files 'wings.service' --no-legend | grep -q wings; then
  systemctl restart wings
  echo "-> wings : $(systemctl is-active wings)"
fi

# Pulihkan proses Node.js PM2 jika terpasang
if command -v pm2 >/dev/null 2>&1; then
  pm2 resurrect >/dev/null 2>&1 || pm2 restart all >/dev/null 2>&1 || true
  echo "-> pm2 : proses dipulihkan"
fi

echo "=== [5/5] Verifikasi Akhir ==="
systemctl is-active --quiet mariadb && echo "[OK] MariaDB ACTIVE" || echo "[GAGAL] MariaDB masih mati — cek: journalctl -u mariadb -n 30 --no-pager"
