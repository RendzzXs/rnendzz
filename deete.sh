
#!/bin/bash
set -u

echo "======================================"
echo " RENDZZ CLOUDS VPS CLEANUP AUDIT"
echo " PTERODACTYL PROTECTION ENABLED"
echo "======================================"

echo
echo "[1] OS"
cat /etc/os-release | head -6

echo
echo "[2] Installed packages"
dpkg-query -W -f='${binary:Package}\n' 2>/dev/null

echo
echo "[3] Active services"
systemctl list-units --type=service --state=running --no-pager

echo
echo "[4] Installed runtimes"
node -v 2>/dev/null || true
npm -v 2>/dev/null || true
php -v 2>/dev/null | head -2 || true
python3 --version
docker --version 2>/dev/null || true

echo
echo "[5] Web directories"
ls -lah /var/www/

echo
echo "[6] Important services"
for S in nginx mariadb mysql redis-server wings; do
    systemctl is-active "$S" 2>/dev/null || true
done

echo
echo "[7] Pterodactyl check"
if [ -d /var/www/pterodactyl ]; then
    echo "PTERODACTYL PANEL FOUND - PROTECTED"
else
    echo "Panel directory not found"
fi

echo
echo "[8] Recent APT history"
ls -lt /var/log/apt/history.log* 2>/dev/null | head -10

echo
echo "======================================"
echo " AUDIT COMPLETE - NO CHANGES MADE"
echo "======================================"
