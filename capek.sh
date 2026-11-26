#!/bin/bash

# --- Konfigurasi Dasar ---
DB_USER="root"
DB_PASS="root"  # Ganti jika password root MySQL kamu sudah ada
DB_HOST="localhost"
DB_NAME="database_kamu" # Ganti dengan nama database aplikasimu

echo "=== Memulai Perbaikan Error 1698 MySQL ==="

# 1. Deteksi apakah MySQL berjalan
if ! systemctl is-active --quiet mysql && ! systemctl is-active --quiet mariadb; then
    echo "❌ MySQL/MariaDB tidak berjalan. Menyalakan..."
    sudo systemctl start mysql || sudo systemctl start mariadb
fi

# 2. Perbaiki user 'root' untuk bisa login pakai password (bukan socket)
echo "🔧 Memperbaiki autentikasi user 'root'..."
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASS}';
FLUSH PRIVILEGES;
EOF

if [ $? -ne 0 ]; then
    echo "❌ Gagal mengubah password root. Coba jalankan script ini dengan sudo."
    exit 1
fi

# 3. Uji koneksi dengan password baru
echo "🔍 Menguji koneksi database..."
mysql -u ${DB_USER} -p${DB_PASS} -h ${DB_HOST} -e "SHOW DATABASES;" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Koneksi database BERHASIL!"
else
    echo "❌ Koneksi database MASIH GAGAL. Cek konfigurasi."
    exit 1
fi

# 4. Cek apakah database aplikasi ada
DB_EXISTS=$(mysql -u ${DB_USER} -p${DB_PASS} -h ${DB_HOST} -e "SHOW DATABASES LIKE '${DB_NAME}';" | grep -c "${DB_NAME}")

if [ "$DB_EXISTS" -eq 0 ]; then
    echo "⚠️ Database '${DB_NAME}' tidak ditemukan. Membuat database baru..."
    mysql -u ${DB_USER} -p${DB_PASS} -h ${DB_HOST} -e "CREATE DATABASE ${DB_NAME};"
fi

echo "✅ Perbaikan Selesai."
echo "👉 Jangan lupa update file .env / config aplikasi dengan:"
echo "   DB_USERNAME=${DB_USER}"
echo "   DB_PASSWORD=${DB_PASS}"
echo "   DB_DATABASE=${DB_NAME}"
