#!/bin/bash
# ============================================
#   👑 RENDZZ ULTIMATE INSTALLER v16.1 (FIXED)
#   1x Klik • Auto Fix • All Features
# ============================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}❌ Harus root!${NC}"; exit 1; }

clear
echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  👑 RENDZZ ULTIMATE INSTALLER v16.1        ║${NC}"
echo -e "${CYAN}║  Auto Install • Landing Page • Full Admin  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
echo ""

# ============ INPUT ============
read -p "👉 Masukkan Domain Web (contoh: panel.domain.com): " DOMAIN
[[ -z "$DOMAIN" ]] && { echo -e "${RED}❌ Domain tidak boleh kosong!${NC}"; exit 1; }

read -p "👉 Email SSL (buat Let's Encrypt): " EMAIL
[[ -z "$EMAIL" ]] && EMAIL="admin@$DOMAIN"

echo ""

# ============ VARIABEL ============
WEB_ROOT="/var/www/$DOMAIN"
DB_NAME="reseller_$(echo $DOMAIN | tr '.' '_' | cut -c1-20)"
DB_PASS=$(openssl rand -hex 12)
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

# ============================================
# 1. AUTO FIX & INSTALL DEPENDENCY
# ============================================
echo -e "${CYAN}[1/7] Auto Fix Lock & Install Dependency...${NC}"
export DEBIAN_FRONTEND=noninteractive

# Hapus lock file tanpa membunuh proses apt yang sedang berjalan
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock /var/lib/apt/lists/lock
dpkg --configure -a >/dev/null 2>&1
apt --fix-broken install -y -qq >/dev/null 2>&1

# Update & Install
apt update -qq 2>/dev/null
apt install -y software-properties-common curl wget git unzip >/dev/null 2>&1
add-apt-repository -y ppa:ondrej/php >/dev/null 2>&1
apt update -qq 2>/dev/null

# Install PHP, Nginx, MariaDB
apt install -y nginx php8.3-fpm php8.3-mysql php8.3-mbstring php8.3-curl php8.3-xml php8.3-zip php8.3-gd php8.3-intl php8.3-bcmath mariadb-server mariadb-client certbot python3-certbot-nginx >/dev/null 2>&1
apt install -y -o Dpkg::Options::="--force-confnew" mariadb-server >/dev/null 2>&1

systemctl enable --now nginx php8.3-fpm mariadb >/dev/null 2>&1
echo -e "${GREEN}  ✅ Dependency Siap${NC}\n"

# ============================================
# 2. SETUP DATABASE
# ============================================
echo -e "${CYAN}[2/7] Setup Database...${NC}"
# Gunakan sudo mysql untuk MariaDB fresh install
mysql << SQLEOF 2>/dev/null
DROP DATABASE IF EXISTS \`$DB_NAME\`;
CREATE DATABASE \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'reseller'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO 'reseller'@'localhost';
FLUSH PRIVILEGES;

USE \`$DB_NAME\`;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin','user') DEFAULT 'user',
    status ENUM('active','banned') DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE servers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    server_name VARCHAR(100),
    ptero_id INT,
    ram INT,
    email VARCHAR(100) DEFAULT NULL,
    password VARCHAR(100) DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE settings (k VARCHAR(50) PRIMARY KEY, v TEXT);
CREATE TABLE chats (id INT AUTO_INCREMENT PRIMARY KEY, user_id INT, username VARCHAR(50), message TEXT, is_admin TINYINT(1) DEFAULT 0, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE announcements (id INT AUTO_INCREMENT PRIMARY KEY, message TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);

INSERT INTO settings VALUES 
('ptero_domain', 'https://pterodactyl-anda.com'),
('ptla', 'ptla_xxx'),
('ptlc', 'ptlc_xxx'),
('location_id', '1'),
('egg_id', '15');
SQLEOF

# Admin Secret (aulia)
ADMIN_HASH=$(php -r "echo password_hash('aulia55', PASSWORD_BCRYPT);")
mysql "$DB_NAME" -e "INSERT INTO users (username, email, password, role) VALUES ('aulia', 'aulia@$DOMAIN', '$ADMIN_HASH', 'admin');" 2>/dev/null
echo -e "${GREEN}  ✅ Database & Admin 'aulia' Siap${NC}\n"

# ============================================
# 3. BIKIN FOLDER & CONFIG
# ============================================
echo -e "${CYAN}[3/7] Bikin File Web...${NC}"
rm -rf "$WEB_ROOT"
mkdir -p "$WEB_ROOT"/{includes,assets/css,api,admin}

cat > "$WEB_ROOT/includes/config.php" << PHPEOF
<?php
session_start();
date_default_timezone_set('Asia/Jakarta');
define('DB_HOST', 'localhost');
define('DB_NAME', '$DB_NAME');
define('DB_USER', 'reseller');
define('DB_PASS', '$DB_PASS');
define('SITE_NAME', 'Rendzz Reseller');
try {
    \$pdo = new PDO("mysql:host=".DB_HOST.";dbname=".DB_NAME.";charset=utf8mb4", DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (PDOException \$e) { die("DB Error: " . \$e->getMessage()); }
function isLoggedIn() { return isset(\$_SESSION['user_id']); }
function isAdmin() { return isLoggedIn() && \$_SESSION['role'] === 'admin'; }
function requireLogin() { if (!isLoggedIn()) { header('Location: /login.php'); exit; } }
function requireAdmin() { if (!isAdmin()) { header('Location: /'); exit; } }
function getSetting(\$pdo, \$k, \$default = '') {
    \$s = \$pdo->prepare("SELECT v FROM settings WHERE k=?"); \$s->execute([\$k]);
    \$r = \$s->fetch(); return \$r ? \$r['v'] : \$default;
}
PHPEOF

echo -e "${GREEN}  ✅ Config OK${NC}"

# ============================================
# 4. CSS (PRO MAX + THEME + LANDING)
# ============================================
echo -e "${CYAN}[4/7] Bikin CSS Premium...${NC}"
cat > "$WEB_ROOT/assets/css/style.css" << 'CSSEOF'
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

:root {
    --bg: #050508;
    --bg-gradient: radial-gradient(circle at 0% 0%, #1a1a2e 0%, #050508 50%), radial-gradient(circle at 100% 100%, #16213e 0%, transparent 50%);
    --card: rgba(30, 30, 50, 0.5);
    --glass-border: rgba(255, 255, 255, 0.08);
    --text: #ffffff;
    --text-muted: #94a3b8;
    --primary: #6366f1;
    --primary-glow: rgba(99, 102, 241, 0.5);
    --success: #10b981;
    --danger: #ef4444;
    --warning: #f59e0b;
    --gradient: linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #ec4899 100%);
}

[data-theme="light"] {
    --bg: #f8fafc;
    --bg-gradient: radial-gradient(circle at 0% 0%, #e0e7ff 0%, #f8fafc 50%);
    --card: rgba(255, 255, 255, 0.8);
    --glass-border: rgba(0, 0, 0, 0.08);
    --text: #0f172a;
    --text-muted: #64748b;
}

* { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Plus Jakarta Sans', sans-serif; }
body {
    background: var(--bg); background-image: var(--bg-gradient); background-attachment: fixed;
    color: var(--text); min-height: 100vh; padding-top: 70px; padding-bottom: 80px;
    -webkit-font-smoothing: antialiased; transition: background 0.3s;
}
a { color: inherit; text-decoration: none; }
.container { max-width: 800px; margin: 0 auto; padding: 20px; }

/* NAVBAR */
.top-nav {
    position: fixed; top: 0; left: 0; right: 0;
    display: flex; justify-content: space-between; align-items: center;
    padding: 12px 20px;
    background: rgba(10, 10, 20, 0.85); backdrop-filter: blur(20px);
    border-bottom: 1px solid var(--glass-border); z-index: 9998;
}
[data-theme="light"] .top-nav { background: rgba(255,255,255,0.85); }
.brand { font-size: 1.2em; font-weight: 800; background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; display: flex; align-items: center; gap: 8px; }
.nav-actions { display: flex; gap: 8px; }
.nav-btn {
    width: 40px; height: 40px; border-radius: 12px;
    background: var(--card); border: 1px solid var(--glass-border);
    color: var(--text); font-size: 1.1em; cursor: pointer;
    display: flex; align-items: center; justify-content: center; transition: all 0.3s;
}
.nav-btn:hover { border-color: var(--primary); color: var(--primary); }

/* SIDEBAR */
.sidebar-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.7); backdrop-filter: blur(5px); z-index: 9999; opacity: 0; visibility: hidden; transition: all 0.3s; }
.sidebar-overlay.active { opacity: 1; visibility: visible; }
.sidebar {
    position: fixed; top: 0; left: -320px; width: 300px; height: 100vh;
    background: var(--card); backdrop-filter: blur(20px);
    border-right: 1px solid var(--glass-border); z-index: 10000;
    transition: left 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275); overflow-y: auto;
}
.sidebar.open { left: 0; }
.sidebar-header { padding: 20px; border-bottom: 1px solid var(--glass-border); display: flex; justify-content: space-between; align-items: center; }
.sidebar-title { font-size: 1.1em; font-weight: 800; background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
.sidebar-nav { padding: 15px; }
.sidebar-label { font-size: 0.7em; color: var(--text-muted); text-transform: uppercase; letter-spacing: 1.5px; font-weight: 700; padding: 15px 15px 8px; }
.sidebar-link { display: flex; align-items: center; gap: 12px; padding: 12px 15px; border-radius: 12px; color: var(--text); font-weight: 600; font-size: 0.95em; transition: all 0.2s; margin-bottom: 2px; }
.sidebar-link:hover { background: rgba(99, 102, 241, 0.1); color: var(--primary); transform: translateX(4px); }
.sidebar-link i { width: 22px; text-align: center; font-size: 1.1em; color: var(--text-muted); }
.sidebar-link:hover i { color: var(--primary); }

/* CARD */
.card { background: var(--card); backdrop-filter: blur(20px); border: 1px solid var(--glass-border); border-radius: 20px; padding: 24px; margin-bottom: 20px; transition: all 0.3s; animation: slideUp 0.5s ease-out; }
@keyframes slideUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

/* BUTTONS */
.btn { padding: 12px 20px; border-radius: 12px; border: none; font-weight: 700; font-family: inherit; font-size: 0.9em; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; gap: 8px; transition: all 0.3s; text-decoration: none; }
.btn-primary { background: var(--gradient); color: #fff; box-shadow: 0 4px 15px var(--primary-glow); }
.btn-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 25px var(--primary-glow); }
.btn-danger { background: rgba(239, 68, 68, 0.15); color: var(--danger); border: 1px solid var(--danger); }
.btn-danger:hover { background: var(--danger); color: #fff; }
.btn-success { background: rgba(16, 185, 129, 0.15); color: var(--success); border: 1px solid var(--success); }
.btn-warning { background: rgba(245, 158, 11, 0.15); color: var(--warning); border: 1px solid var(--warning); }
.btn-block { width: 100%; }
.btn-sm { padding: 8px 12px; font-size: 0.8em; border-radius: 8px; }
.btn-large { padding: 16px 32px; font-size: 1em; border-radius: 14px; }

/* FORMS */
.form-group { margin-bottom: 16px; }
.form-group label { display: block; margin-bottom: 8px; font-size: 0.85em; color: var(--text-muted); font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }
.form-group input, .form-group select, .form-group textarea { width: 100%; padding: 12px 16px; border: 1px solid var(--glass-border); border-radius: 12px; background: rgba(0, 0, 0, 0.3); color: var(--text); font-family: inherit; font-size: 0.95em; outline: none; transition: all 0.2s; }
.form-group input:focus, .form-group select:focus, .form-group textarea:focus { border-color: var(--primary); box-shadow: 0 0 0 3px var(--primary-glow); }

/* ALERTS */
.alert { padding: 14px 18px; border-radius: 12px; margin-bottom: 16px; font-size: 0.9em; font-weight: 600; display: flex; align-items: center; gap: 10px; }
.alert-error { background: rgba(239, 68, 68, 0.15); color: var(--danger); border: 1px solid rgba(239, 68, 68, 0.3); }
.alert-success { background: rgba(16, 185, 129, 0.15); color: var(--success); border: 1px solid rgba(16, 185, 129, 0.3); }

/* BADGES */
.badge { padding: 4px 10px; border-radius: 6px; font-size: 0.75em; font-weight: 800; text-transform: uppercase; }
.badge-active { background: rgba(16, 185, 129, 0.15); color: var(--success); }
.badge-banned { background: rgba(239, 68, 68, 0.15); color: var(--danger); }

/* TABLE */
.table { width: 100%; border-collapse: collapse; font-size: 0.85em; }
.table th, .table td { padding: 12px 8px; text-align: left; border-bottom: 1px solid var(--glass-border); }
.table th { color: var(--text-muted); font-size: 0.75em; text-transform: uppercase; font-weight: 700; }

/* BOTTOM NAV */
.bottom-nav { position: fixed; bottom: 15px; left: 15px; right: 15px; background: var(--card); backdrop-filter: blur(20px); border: 1px solid var(--glass-border); border-radius: 24px; display: flex; justify-content: space-around; padding: 10px 0; z-index: 9997; max-width: 500px; margin: 0 auto; box-shadow: 0 10px 40px rgba(0,0,0,0.3); }
.nav-item { display: flex; flex-direction: column; align-items: center; gap: 4px; color: var(--text-muted); font-size: 0.7em; font-weight: 700; padding: 8px 16px; border-radius: 16px; transition: all 0.3s; }
.nav-item i { font-size: 1.4em; }
.nav-item:hover, .nav-item.active { color: var(--primary); background: rgba(99, 102, 241, 0.15); transform: translateY(-4px); }

/* TABS */
.tabs { display: flex; gap: 8px; margin-bottom: 20px; overflow-x: auto; padding: 6px; background: rgba(0,0,0,0.2); border-radius: 16px; border: 1px solid var(--glass-border); }
.tab-btn { padding: 10px 18px; border-radius: 12px; border: none; background: transparent; color: var(--text-muted); cursor: pointer; font-weight: 700; font-size: 0.85em; white-space: nowrap; transition: all 0.3s; display: flex; align-items: center; gap: 6px; }
.tab-btn.active { background: var(--gradient); color: #fff; }
.tab-content { display: none; }
.tab-content.active { display: block; animation: slideUp 0.3s; }

/* STATS */
.stat-value { font-size: 2em; font-weight: 800; background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; display: block; line-height: 1.2; }
.stat-label { font-size: 0.7em; color: var(--text-muted); text-transform: uppercase; letter-spacing: 1px; font-weight: 700; margin-top: 4px; }

/* FOOTER */
.copyright { text-align: center; padding: 30px 20px; font-size: 0.8em; color: var(--text-muted); margin-top: 30px; }
.copyright span { background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; font-weight: 800; }

/* HERO (Landing) */
.hero-section { text-align: center; padding: 60px 20px 40px; }
.hero-title { font-size: 2.8em; font-weight: 800; line-height: 1.15; margin-bottom: 20px; letter-spacing: -1.5px; }
.hero-title .gradient-text { background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; display: block; }
.hero-subtitle { font-size: 1.1em; color: var(--text-muted); max-width: 600px; margin: 0 auto 35px; line-height: 1.6; }

/* LANDING STATS */
.stats-section { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; max-width: 800px; margin: 0 auto 60px; padding: 0 20px; }
.stat-card { background: var(--card); backdrop-filter: blur(20px); border: 1px solid var(--glass-border); border-radius: 20px; padding: 30px 15px; text-align: center; transition: all 0.4s; }
.stat-card:hover { transform: translateY(-8px); border-color: var(--primary); box-shadow: 0 20px 40px var(--primary-glow); }
.stat-icon { width: 55px; height: 55px; border-radius: 16px; display: flex; align-items: center; justify-content: center; margin: 0 auto 15px; font-size: 1.4em; color: #fff; }
.stat-number { font-size: 2em; font-weight: 800; background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; line-height: 1.2; }
.stat-text { font-size: 0.8em; color: var(--text-muted); text-transform: uppercase; letter-spacing: 1px; font-weight: 700; margin-top: 4px; }

/* SECTION */
.section { padding: 50px 20px; max-width: 1000px; margin: 0 auto; }
.section-title { text-align: center; font-size: 1.9em; font-weight: 800; margin-bottom: 12px; letter-spacing: -1px; }
.section-subtitle { text-align: center; color: var(--text-muted); font-size: 1em; margin-bottom: 40px; }

/* FEATURE */
.feature-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 18px; }
.feature-item { background: var(--card); backdrop-filter: blur(20px); border: 1px solid var(--glass-border); border-radius: 20px; padding: 25px 22px; transition: all 0.4s; }
.feature-item:hover { transform: translateY(-6px); border-color: var(--primary); box-shadow: 0 15px 35px var(--primary-glow); }
.feature-icon { width: 55px; height: 55px; border-radius: 16px; display: flex; align-items: center; justify-content: center; font-size: 1.3em; color: #fff; margin-bottom: 18px; }
.feature-item h3 { font-size: 1.1em; margin-bottom: 8px; }
.feature-item p { font-size: 0.88em; color: var(--text-muted); line-height: 1.55; }

/* STEPS */
.steps-container { display: flex; flex-direction: column; gap: 16px; max-width: 700px; margin: 0 auto; }
.step { display: flex; align-items: center; gap: 18px; background: var(--card); backdrop-filter: blur(20px); border: 1px solid var(--glass-border); border-radius: 20px; padding: 22px; transition: all 0.3s; }
.step:hover { transform: translateX(6px); border-color: var(--primary); }
.step-number { width: 55px; height: 55px; border-radius: 50%; background: var(--gradient); display: flex; align-items: center; justify-content: center; font-size: 1.4em; font-weight: 800; color: #fff; flex-shrink: 0; box-shadow: 0 8px 20px var(--primary-glow); }
.step-content h3 { font-size: 1.05em; margin-bottom: 4px; }
.step-content p { font-size: 0.88em; color: var(--text-muted); }

/* TESTIMONIAL */
.testimonial-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(270px, 1fr)); gap: 18px; }
.testimonial { background: var(--card); backdrop-filter: blur(20px); border: 1px solid var(--glass-border); border-radius: 20px; padding: 22px; transition: all 0.3s; }
.testimonial:hover { transform: translateY(-5px); border-color: var(--primary); }
.testimonial-stars { color: #f59e0b; font-size: 0.95em; margin-bottom: 10px; }
.testimonial-text { font-size: 0.9em; color: var(--text); line-height: 1.6; margin-bottom: 14px; font-style: italic; }
.testimonial-author { display: flex; align-items: center; gap: 12px; }
.testimonial-avatar { width: 42px; height: 42px; border-radius: 50%; background: var(--gradient); display: flex; align-items: center; justify-content: center; color: #fff; font-weight: 800; font-size: 1em; }
.testimonial-info h4 { font-size: 0.9em; margin-bottom: 2px; }
.testimonial-info p { font-size: 0.78em; color: var(--text-muted); }

/* FAQ */
.faq-container { max-width: 700px; margin: 0 auto; }
.faq-item { background: var(--card); backdrop-filter: blur(20px); border: 1px solid var(--glass-border); border-radius: 16px; margin-bottom: 12px; overflow: hidden; transition: all 0.3s; }
.faq-item:hover { border-color: var(--primary); }
.faq-question { padding: 18px 22px; cursor: pointer; display: flex; justify-content: space-between; align-items: center; font-weight: 700; font-size: 0.95em; user-select: none; }
.faq-question i { color: var(--primary); transition: transform 0.3s; }
.faq-item.open .faq-question i { transform: rotate(45deg); }
.faq-answer { max-height: 0; overflow: hidden; transition: max-height 0.4s ease, padding 0.4s ease; padding: 0 22px; color: var(--text-muted); font-size: 0.92em; line-height: 1.6; }
.faq-item.open .faq-answer { max-height: 300px; padding: 0 22px 18px; }

/* CTA FINAL */
.cta-final { text-align: center; padding: 60px 20px; background: linear-gradient(135deg, rgba(99,102,241,0.2), rgba(236,72,153,0.1)); border-radius: 30px; border: 1px solid rgba(99,102,241,0.3); max-width: 800px; margin: 40px auto; }
.cta-final h2 { font-size: 2em; margin-bottom: 12px; letter-spacing: -1px; }
.cta-final p { font-size: 1em; color: var(--text-muted); margin-bottom: 25px; }

/* RESPONSIVE */
@media (max-width: 600px) {
    .hero-title { font-size: 2em; }
    .hero-subtitle { font-size: 1em; }
    .stats-section { grid-template-columns: 1fr; }
    .section-title { font-size: 1.5em; }
    .cta-final h2 { font-size: 1.5em; }
    .step { flex-direction: column; text-align: center; }
    .container { padding: 15px; }
    .card { padding: 18px; }
}
CSSEOF
echo -e "${GREEN}  ✅ CSS OK${NC}\n"

# ============================================
# 5. HEADER & FOOTER
# ============================================
echo -e "${CYAN}[5/7] Bikin Header & Footer...${NC}"

cat > "$WEB_ROOT/includes/header.php" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="id" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= $pageTitle ?? 'Home' ?> — <?= SITE_NAME ?></title>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<link rel="stylesheet" href="/assets/css/style.css">
<script>document.documentElement.setAttribute('data-theme', localStorage.getItem('theme') || 'dark');</script>
</head>
<body>

<div class="top-nav">
    <a href="/" class="brand"><i class="fas fa-bolt"></i> RendzzPanel</a>
    <div class="nav-actions">
        <button class="nav-btn" onclick="toggleSidebar()"><i class="fas fa-bars"></i></button>
        <button class="nav-btn" onclick="toggleTheme()"><i class="fas fa-moon" id="themeIcon"></i></button>
    </div>
</div>

<div class="sidebar-overlay" id="sidebarOverlay" onclick="toggleSidebar()"></div>
<div class="sidebar" id="sidebar">
    <div class="sidebar-header">
        <div class="sidebar-title"><i class="fas fa-bolt"></i> RENDZZ PANEL</div>
        <button class="nav-btn" onclick="toggleSidebar()" style="width:35px;height:35px"><i class="fas fa-times"></i></button>
    </div>
    <nav class="sidebar-nav">
        <?php if (isLoggedIn()): ?>
            <div class="sidebar-label">Menu Utama</div>
            <a href="/dashboard.php" class="sidebar-link"><i class="fas fa-home"></i> Dashboard</a>
            <a href="/chat.php" class="sidebar-link"><i class="fas fa-comments"></i> Global Chat</a>
            <a href="/profile.php" class="sidebar-link"><i class="fas fa-user"></i> Profile Saya</a>
            <?php if (isAdmin()): ?>
                <div class="sidebar-label">Admin Panel</div>
                <a href="/admin/" class="sidebar-link"><i class="fas fa-shield-halved" style="color:var(--warning)"></i> X-Admin</a>
            <?php endif; ?>
            <div class="sidebar-label">Lainnya</div>
            <a href="/logout.php" class="sidebar-link" style="color:var(--danger)"><i class="fas fa-sign-out-alt"></i> Logout</a>
        <?php else: ?>
            <div class="sidebar-label">Menu</div>
            <a href="/" class="sidebar-link"><i class="fas fa-home"></i> Home</a>
            <a href="/login.php" class="sidebar-link"><i class="fas fa-sign-in-alt"></i> Login</a>
            <a href="/register.php" class="sidebar-link"><i class="fas fa-user-plus"></i> Daftar</a>
        <?php endif; ?>
    </nav>
</div>

<script>
function toggleSidebar() {
    document.getElementById('sidebar').classList.toggle('open');
    document.getElementById('sidebarOverlay').classList.toggle('active');
}
function toggleTheme() {
    const next = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('theme', next);
    updateIcon();
}
function updateIcon() {
    const theme = document.documentElement.getAttribute('data-theme');
    const icon = document.getElementById('themeIcon');
    if (icon) icon.className = theme === 'dark' ? 'fas fa-moon' : 'fas fa-sun';
}
updateIcon();
</script>
HTMLEOF

cat > "$WEB_ROOT/includes/footer.php" << 'HTMLEOF'
<?php if (isLoggedIn()): ?>
<div class="bottom-nav">
    <a href="/dashboard.php" class="nav-item <?= basename($_SERVER['PHP_SELF']) == 'dashboard.php' ? 'active' : '' ?>"><i class="fas fa-home"></i><span>Home</span></a>
    <a href="/chat.php" class="nav-item <?= basename($_SERVER['PHP_SELF']) == 'chat.php' ? 'active' : '' ?>"><i class="fas fa-comments"></i><span>Chat</span></a>
    <?php if (isAdmin()): ?><a href="/admin/" class="nav-item <?= strpos($_SERVER['PHP_SELF'], '/admin/') !== false ? 'active' : '' ?>"><i class="fas fa-crown" style="color:var(--warning)"></i><span>Admin</span></a><?php endif; ?>
    <a href="/profile.php" class="nav-item <?= basename($_SERVER['PHP_SELF']) == 'profile.php' ? 'active' : '' ?>"><i class="fas fa-user"></i><span>Profile</span></a>
</div>
<?php endif; ?>
<div class="copyright">&copy; <?= date('Y') ?> By <span>Rendzz Official</span></div>
</body></html>
HTMLEOF
echo -e "${GREEN}  ✅ Header & Footer OK${NC}\n"

# ============================================
# 6. SEMUA HALAMAN WEB
# ============================================
echo -e "${CYAN}[6/7] Bikin Halaman Web...${NC}"

# --- INDEX (LANDING PAGE) ---
cat > "$WEB_ROOT/index.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
$pageTitle = 'Home';
try {
    $totalUsers = $pdo->query("SELECT COUNT(*) FROM users WHERE role='user'")->fetchColumn();
    $totalServers = $pdo->query("SELECT COUNT(*) FROM servers")->fetchColumn();
    $ramTotal = $pdo->query("SELECT SUM(ram) FROM servers")->fetchColumn() ?: 0;
    $ramTotalGB = round($ramTotal / 1024, 1);
} catch (Exception $e) { $totalUsers = 0; $totalServers = 0; $ramTotalGB = 0; }
include __DIR__ . '/includes/header.php';
?>

<section class="hero-section">
    <h1 class="hero-title">Buat Server Impianmu <span class="gradient-text">Dalam Hitungan Detik</span></h1>
    <p class="hero-subtitle">Deploy server Minecraft, Node.js, Bot WhatsApp dengan mudah. Pilih RAM, klik deploy, server langsung aktif!</p>
    <div style="display:flex; gap:12px; justify-content:center; flex-wrap:wrap;">
        <a href="/register.php" class="btn btn-primary btn-large"><i class="fas fa-rocket"></i> Daftar Gratis</a>
        <a href="/login.php" class="btn btn-large" style="background:var(--card); color:var(--text); border:1px solid var(--glass-border)"><i class="fas fa-sign-in-alt"></i> Login</a>
    </div>
</section>

<div class="stats-section">
    <div class="stat-card">
        <div class="stat-icon" style="background:linear-gradient(135deg,#6366f1,#8b5cf6)"><i class="fas fa-users"></i></div>
        <div class="stat-number" data-count="<?= $totalUsers ?>">0</div>
        <div class="stat-text">User Aktif</div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background:linear-gradient(135deg,#10b981,#059669)"><i class="fas fa-server"></i></div>
        <div class="stat-number" data-count="<?= $totalServers ?>">0</div>
        <div class="stat-text">Server Dibuat</div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background:linear-gradient(135deg,#f59e0b,#d97706)"><i class="fas fa-memory"></i></div>
        <div class="stat-number" data-count="<?= $ramTotalGB ?>" data-suffix=" GB">0</div>
        <div class="stat-text">RAM Terpakai</div>
    </div>
</div>

<section class="section">
    <h2 class="section-title">Kenapa Pilih <span style="background:var(--gradient); -webkit-background-clip:text; -webkit-text-fill-color:transparent;">RendzzPanel?</span></h2>
    <p class="section-subtitle">Pengalaman hosting terbaik dengan teknologi modern</p>
    <div class="feature-grid">
        <div class="feature-item">
            <div class="feature-icon" style="background:linear-gradient(135deg,#6366f1,#8b5cf6)"><i class="fas fa-bolt"></i></div>
            <h3>Instant Deploy</h3>
            <p>Server langsung jadi dalam 10 detik setelah klik Deploy.</p>
        </div>
        <div class="feature-item">
            <div class="feature-icon" style="background:linear-gradient(135deg,#10b981,#059669)"><i class="fas fa-shield-halved"></i></div>
            <h3>Aman & Terpercaya</h3>
            <p>Data dienkripsi. Server di datacenter profesional.</p>
        </div>
        <div class="feature-item">
            <div class="feature-icon" style="background:linear-gradient(135deg,#f59e0b,#d97706)"><i class="fas fa-memory"></i></div>
            <h3>RAM Unlimited</h3>
            <p>Pilih paket dari 1GB sampai Unlimited.</p>
        </div>
        <div class="feature-item">
            <div class="feature-icon" style="background:linear-gradient(135deg,#ec4899,#be185d)"><i class="fas fa-headset"></i></div>
            <h3>Support 24/7</h3>
            <p>Admin aktif dan siap bantu via Global Chat.</p>
        </div>
    </div>
</section>

<section class="section">
    <h2 class="section-title">Cara Kerja</h2>
    <p class="section-subtitle">Cuma butuh 3 langkah simpel</p>
    <div class="steps-container">
        <div class="step">
            <div class="step-number">1</div>
            <div class="step-content"><h3>Daftar Gratis</h3><p>Bikin akun dalam 30 detik. Gak perlu kartu kredit.</p></div>
        </div>
        <div class="step">
            <div class="step-number">2</div>
            <div class="step-content"><h3>Pilih RAM & Tipe</h3><p>Tentukan paket RAM (1GB - Unlimited).</p></div>
        </div>
        <div class="step">
            <div class="step-number">3</div>
            <div class="step-content"><h3>Deploy & Selesai</h3><p>Klik Deploy, tunggu 10 detik, server aktif!</p></div>
        </div>
    </div>
</section>

<section class="section">
    <h2 class="section-title">Apa Kata Mereka?</h2>
    <p class="section-subtitle">Ribuan user sudah membuktikan</p>
    <div class="testimonial-grid">
        <div class="testimonial">
            <div class="testimonial-stars"><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i></div>
            <p class="testimonial-text">"Deploy server cuma 10 detik doang. Recommended banget!"</p>
            <div class="testimonial-author"><div class="testimonial-avatar">A</div><div class="testimonial-info"><h4>Andi P.</h4><p>Content Creator</p></div></div>
        </div>
        <div class="testimonial">
            <div class="testimonial-stars"><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i></div>
            <p class="testimonial-text">"Admin fast respon banget. Pelayanan top!"</p>
            <div class="testimonial-author"><div class="testimonial-avatar">S</div><div class="testimonial-info"><h4>Siti R.</h4><p>Bot Developer</p></div></div>
        </div>
        <div class="testimonial">
            <div class="testimonial-stars"><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i></div>
            <p class="testimonial-text">"RAM Unlimited worth it banget. Gak lag!"</p>
            <div class="testimonial-author"><div class="testimonial-avatar">B</div><div class="testimonial-info"><h4>Budi S.</h4><p>Minecraft Player</p></div></div>
        </div>
    </div>
</section>

<section class="section">
    <h2 class="section-title">FAQ</h2>
    <p class="section-subtitle">Belum nemu jawaban? Tanya admin</p>
    <div class="faq-container">
        <div class="faq-item"><div class="faq-question">Apakah ini gratis?<i class="fas fa-plus"></i></div><div class="faq-answer">Ya! Daftar gratis. Deploy server sesuai paket RAM yang tersedia tanpa biaya tersembunyi.</div></div>
        <div class="faq-item"><div class="faq-question">Berapa lama server aktif?<i class="fas fa-plus"></i></div><div class="faq-answer">Server aktif 24/7 selama masa aktif panel. Bisa diperpanjang tanpa downtime.</div></div>
        <div class="faq-item"><div class="faq-question">Tipe server apa saja?<i class="fas fa-plus"></i></div><div class="faq-answer">Minecraft, Node.js, Python, Bot WhatsApp, Telegram Bot, Web Hosting, dll.</div></div>
        <div class="faq-item"><div class="faq-question">Cara upgrade RAM?<i class="fas fa-plus"></i></div><div class="faq-answer">Kontak admin via Global Chat. Tim kami akan bantu upgrade.</div></div>
        <div class="faq-item"><div class="faq-question">Data saya aman?<i class="fas fa-plus"></i></div><div class="faq-answer">100% aman. Server di datacenter profesional dengan enkripsi SSL.</div></div>
    </div>
</section>

<div class="cta-final">
    <h2>Siap Mulai Deploy?</h2>
    <p>Gratis. Server siap dalam hitungan detik.</p>
    <div style="display:flex; gap:12px; justify-content:center; flex-wrap:wrap;">
        <a href="/register.php" class="btn btn-primary btn-large"><i class="fas fa-rocket"></i> Daftar</a>
        <a href="/login.php" class="btn btn-large" style="background:rgba(255,255,255,0.1); color:var(--text); border:1px solid var(--glass-border)"><i class="fas fa-sign-in-alt"></i> Login</a>
    </div>
</div>

<script>
document.querySelectorAll('.stat-number').forEach(el => {
    const target = parseFloat(el.dataset.count);
    const suffix = el.dataset.suffix || '';
    let current = 0;
    const step = target / 40;
    const timer = setInterval(() => {
        current += step;
        if (current >= target) { current = target; clearInterval(timer); }
        el.textContent = (Number.isInteger(target) ? Math.round(current) : current.toFixed(1)) + suffix;
    }, 25);
});
document.querySelectorAll('.faq-question').forEach(q => {
    q.addEventListener('click', () => {
        const parent = q.closest('.faq-item');
        document.querySelectorAll('.faq-item').forEach(i => { if (i !== parent) i.classList.remove('open'); });
        parent.classList.toggle('open');
    });
});
</script>

<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

# --- LOGIN ---
cat > "$WEB_ROOT/login.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
if (isLoggedIn()) { header('Location: /dashboard.php'); exit; }
$err = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $u = trim($_POST['username']); $p = $_POST['password'];
    $s = $pdo->prepare("SELECT * FROM users WHERE username=?"); $s->execute([$u]); $user = $s->fetch();
    if ($user && password_verify($p, $user['password'])) {
        if ($user['status'] === 'banned') { $err = 'Akun dibanned!'; }
        else {
            $_SESSION['user_id'] = $user['id']; $_SESSION['username'] = $user['username']; $_SESSION['role'] = $user['role'];
            header('Location: /dashboard.php'); exit;
        }
    } else { $err = 'Username/Password salah!'; }
}
$pageTitle = 'Login'; include __DIR__ . '/includes/header.php';
?>
<div class="container" style="max-width:420px; margin-top:40px">
    <div class="card" style="text-align:center; padding:35px;">
        <div style="width:70px;height:70px;border-radius:50%;background:var(--gradient);display:flex;align-items:center;justify-content:center;font-size:1.8em;color:#fff;margin:0 auto 20px;box-shadow:0 10px 30px var(--primary-glow);"><i class="fas fa-lock"></i></div>
        <h2 style="margin-bottom:5px;">Selamat Datang</h2>
        <p style="color:var(--text-muted); font-size:0.9em; margin-bottom:25px;">Login untuk akses dashboard</p>
        <?php if ($err): ?><div class="alert alert-error"><i class="fas fa-exclamation-circle"></i> <?= $err ?></div><?php endif; ?>
        <form method="POST" style="text-align:left;">
            <div class="form-group"><label>Username</label><input type="text" name="username" placeholder="Masukkan username" required autofocus></div>
            <div class="form-group"><label>Password</label><input type="password" name="password" placeholder="Masukkan password" required></div>
            <button class="btn btn-primary btn-block"><i class="fas fa-sign-in-alt"></i> Masuk</button>
        </form>
        <p style="margin-top:20px; font-size:0.9em; color:var(--text-muted);">Belum punya akun? <a href="/register.php" style="color:var(--primary); font-weight:700;">Daftar</a></p>
    </div>
</div>
<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

# --- REGISTER ---
cat > "$WEB_ROOT/register.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
if (isLoggedIn()) { header('Location: /dashboard.php'); exit; }
$err = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $u = trim($_POST['username']); $e = trim($_POST['email']); $p = $_POST['password'];
    if (strlen($p) < 6) $err = 'Password minimal 6 karakter';
    else {
        $s = $pdo->prepare("SELECT id FROM users WHERE username=? OR email=?"); $s->execute([$u, $e]);
        if ($s->fetch()) $err = 'Username/Email sudah dipakai!';
        else {
            $pdo->prepare("INSERT INTO users (username, email, password) VALUES (?,?,?)")->execute([$u, $e, password_hash($p, PASSWORD_BCRYPT)]);
            header('Location: /login.php'); exit;
        }
    }
}
$pageTitle = 'Register'; include __DIR__ . '/includes/header.php';
?>
<div class="container" style="max-width:420px; margin-top:40px">
    <div class="card" style="text-align:center; padding:35px;">
        <div style="width:70px;height:70px;border-radius:50%;background:linear-gradient(135deg,#10b981,#059669);display:flex;align-items:center;justify-content:center;font-size:1.8em;color:#fff;margin:0 auto 20px;box-shadow:0 10px 30px rgba(16,185,129,0.4);"><i class="fas fa-user-plus"></i></div>
        <h2 style="margin-bottom:5px;">Buat Akun Baru</h2>
        <p style="color:var(--text-muted); font-size:0.9em; margin-bottom:25px;">Gratis & langsung bisa deploy server</p>
        <?php if ($err): ?><div class="alert alert-error"><i class="fas fa-exclamation-circle"></i> <?= $err ?></div><?php endif; ?>
        <form method="POST" style="text-align:left;">
            <div class="form-group"><label>Username</label><input type="text" name="username" placeholder="Minimal 3 karakter" required></div>
            <div class="form-group"><label>Email</label><input type="email" name="email" placeholder="email@example.com" required></div>
            <div class="form-group"><label>Password</label><input type="password" name="password" placeholder="Minimal 6 karakter" required></div>
            <button class="btn btn-primary btn-block"><i class="fas fa-rocket"></i> Daftar Sekarang</button>
        </form>
        <p style="margin-top:20px; font-size:0.9em; color:var(--text-muted);">Sudah punya akun? <a href="/login.php" style="color:var(--primary); font-weight:700;">Login</a></p>
    </div>
</div>
<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

# --- DASHBOARD ---
cat > "$WEB_ROOT/dashboard.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
requireLogin();
$uid = $_SESSION['user_id'];
$s = $pdo->prepare("SELECT * FROM users WHERE id=?"); $s->execute([$uid]); $me = $s->fetch();
$ann = $pdo->query("SELECT * FROM announcements ORDER BY id DESC LIMIT 1")->fetch();
$msg = ''; $err = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['create'])) {
    $serverName = trim($_POST['server_name']);
    $ram = (int)$_POST['ram'];
    if (!$serverName || !$ram) { $err = 'Isi semua data!'; }
    else {
        $pteroDomain = rtrim(getSetting($pdo, 'ptero_domain'), '/');
        $ptla = getSetting($pdo, 'ptla');
        $loc = getSetting($pdo, 'location_id');
        $egg = getSetting($pdo, 'egg_id');
        $email = $me['username'] . rand(10,99) . "@rendzz.com";
        $password = "Pass" . rand(1000,9999) . "!";
        $headers = ["Accept: application/json", "Content-Type: application/json", "Authorization: Bearer $ptla"];
        $ch = curl_init("$pteroDomain/api/application/users");
        curl_setopt_array($ch, [CURLOPT_POST => true, CURLOPT_RETURNTRANSFER => true, CURLOPT_HTTPHEADER => $headers, CURLOPT_POSTFIELDS => json_encode(["email" => $email, "username" => $me['username'] . rand(100,999), "first_name" => $me['username'], "last_name" => "User", "password" => $password])]);
        $res = json_decode(curl_exec($ch), true); curl_close($ch);
        if (isset($res['errors'])) { $err = 'Gagal buat user: ' . $res['errors'][0]['detail']; }
        else {
            $pteroUserId = $res['attributes']['id'];
            $startup = 'if [[ -d .git ]] && [[ {{AUTO_UPDATE}} == "1" ]]; then git pull; fi; if [[ ! -z ${NODE_PACKAGES} ]]; then /usr/local/bin/npm install ${NODE_PACKAGES}; fi; if [[ ! -z ${UNNODE_PACKAGES} ]]; then /usr/local/bin/npm uninstall ${UNNODE_PACKAGES}; fi; if [ -f /home/container/package.json ]; then /usr/local/bin/npm install; fi; /usr/local/bin/${CMD_RUN}';
            $ch = curl_init("$pteroDomain/api/application/servers");
            curl_setopt_array($ch, [CURLOPT_POST => true, CURLOPT_RETURNTRANSFER => true, CURLOPT_HTTPHEADER => $headers, CURLOPT_POSTFIELDS => json_encode(["name" => $serverName, "description" => "Rendzz", "user" => $pteroUserId, "egg" => (int)$egg, "docker_image" => "ghcr.io/parkervcp/yolks:nodejs_20", "startup" => $startup, "environment" => ["INST" => "npm", "USER_UPLOAD" => "0", "AUTO_UPDATE" => "0", "CMD_RUN" => "npm start"], "limits" => ["memory" => $ram, "swap" => 0, "disk" => $ram * 2, "io" => 500, "cpu" => 100], "feature_limits" => ["databases" => 5, "backups" => 5, "allocations" => 1], "deploy" => ["locations" => [(int)$loc], "dedicated_ip" => false, "port_range" => []]])]);
            $res2 = json_decode(curl_exec($ch), true); curl_close($ch);
            if (isset($res2['errors'])) { $err = 'Gagal buat server: ' . $res2['errors'][0]['detail']; }
            else {
                $pteroServerId = $res2['attributes']['id'];
                $pdo->prepare("INSERT INTO servers (user_id, server_name, ptero_id, ram, email, password) VALUES (?,?,?,?,?,?)")->execute([$uid, $serverName, $pteroServerId, $ram, $email, $password]);
                $msg = "Server <b>$serverName</b> berhasil dibuat!";
            }
        }
    }
}
$pageTitle = 'Dashboard'; include __DIR__ . '/includes/header.php';
?>
<div class="container">
    <?php if ($ann): ?><div style="background:rgba(245,158,11,0.15);border:1px solid var(--warning);color:var(--warning);padding:14px 18px;border-radius:14px;margin-bottom:20px;font-size:0.9em;font-weight:600;"><i class="fas fa-bullhorn"></i> <b>Pengumuman:</b> <?= htmlspecialchars($ann['message']) ?></div><?php endif; ?>
    <?php if ($msg): ?><div class="alert alert-success"><i class="fas fa-check-circle"></i> <?= $msg ?></div><?php endif; ?>
    <?php if ($err): ?><div class="alert alert-error"><i class="fas fa-exclamation-circle"></i> <?= $err ?></div><?php endif; ?>

    <div class="card" style="background:linear-gradient(135deg, rgba(99,102,241,0.15), transparent);">
        <h1 style="font-size:1.4em; margin-bottom:5px;">Halo, <?= htmlspecialchars($me['username']) ?>! <i class="fas fa-hand-wave"></i></h1>
        <p style="color:var(--text-muted); font-size:0.9em;">Siap deploy server baru hari ini?</p>
    </div>

    <div class="card">
        <h2 style="margin-bottom:18px; font-size:1.2em;"><i class="fas fa-rocket" style="color:var(--primary)"></i> Deploy Server</h2>
        <form method="POST">
            <input type="hidden" name="create" value="1">
            <div class="form-group"><label>Nama Server</label><input type="text" name="server_name" placeholder="Contoh: Bot WhatsApp" required></div>
            <div class="form-group">
                <label>Pilih RAM</label>
                <select name="ram" required>
                    <option value="1024">1 GB</option>
                    <option value="2048">2 GB</option>
                    <option value="3072">3 GB</option>
                    <option value="4096">4 GB</option>
                    <option value="8192">8 GB</option>
                    <option value="0">Unlimited (RAM Tanpa Batas)</option>
                </select>
            </div>
            <button class="btn btn-primary btn-block"><i class="fas fa-bolt"></i> Deploy Sekarang</button>
        </form>
    </div>
</div>
<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

# --- PROFILE ---
cat > "$WEB_ROOT/profile.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
requireLogin();
$uid = $_SESSION['user_id'];
$s = $pdo->prepare("SELECT * FROM users WHERE id=?"); $s->execute([$uid]); $me = $s->fetch();
$servers = $pdo->prepare("SELECT * FROM servers WHERE user_id=? ORDER BY id DESC"); $servers->execute([$uid]); $servers = $servers->fetchAll();
$pteroDomain = rtrim(getSetting($pdo, 'ptero_domain'), '/');
$pageTitle = 'Profile'; include __DIR__ . '/includes/header.php';
?>
<div class="container">
    <div class="card" style="text-align:center; background:linear-gradient(135deg, rgba(99,102,241,0.15), rgba(139,92,246,0.05)); border-color:var(--primary);">
        <div style="width:80px;height:80px;border-radius:50%;background:var(--gradient);display:flex;align-items:center;justify-content:center;font-size:2.2em;font-weight:800;color:#fff;margin:0 auto 15px;box-shadow:0 10px 30px var(--primary-glow);"><?= strtoupper(substr($me['username'],0,1)) ?></div>
        <h1 style="font-size:1.4em; margin-bottom:5px;">@<?= htmlspecialchars($me['username']) ?></h1>
        <p style="color:var(--text-muted); font-size:0.9em; margin-bottom:15px;"><?= htmlspecialchars($me['email']) ?></p>
        <div style="display:flex; gap:10px; justify-content:center; flex-wrap:wrap;">
            <div style="background:rgba(16,185,129,0.15); padding:8px 18px; border-radius:20px;"><span style="font-size:0.7em; color:var(--text-muted);">STATUS</span> <b style="color:var(--success); margin-left:6px;"><?= strtoupper($me['role']) ?></b></div>
            <div style="background:rgba(99,102,241,0.15); padding:8px 18px; border-radius:20px;"><span style="font-size:0.7em; color:var(--text-muted);">SERVER</span> <b style="color:var(--primary); margin-left:6px;"><?= count($servers) ?></b></div>
        </div>
    </div>

    <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px; margin-bottom:20px;">
        <a href="/dashboard.php" class="card" style="text-align:center; padding:18px; margin:0; text-decoration:none;"><i class="fas fa-rocket" style="color:var(--primary); font-size:1.5em;"></i><div style="font-size:0.85em; font-weight:700; margin-top:6px;">Deploy Server</div></a>
        <a href="<?= htmlspecialchars($pteroDomain) ?>" target="_blank" class="card" style="text-align:center; padding:18px; margin:0; text-decoration:none;"><i class="fas fa-external-link-alt" style="color:var(--success); font-size:1.5em;"></i><div style="font-size:0.85em; font-weight:700; margin-top:6px;">Buka Panel</div></a>
    </div>

    <h2 style="font-size:1.1em; margin-bottom:15px;"><i class="fas fa-server" style="color:var(--primary)"></i> My Servers (<?= count($servers) ?>)</h2>
    <?php if (empty($servers)): ?>
        <div class="card" style="text-align:center; padding:40px; color:var(--text-muted);"><i class="fas fa-server" style="font-size:2.5em; opacity:0.5; margin-bottom:12px;"></i><p>Belum ada server.</p><a href="/dashboard.php" class="btn btn-primary" style="margin-top:15px;">Deploy Sekarang</a></div>
    <?php else: foreach ($servers as $srv): ?>
        <div class="card">
            <div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:12px;">
                <div><div style="font-weight:800; font-size:1.05em;"><?= htmlspecialchars($srv['server_name']) ?></div><div style="font-size:0.8em; color:var(--text-muted); margin-top:2px;">ID #<?= $srv['ptero_id'] ?> • RAM: <?= $srv['ram']==0?'Unlimited':$srv['ram'].'MB' ?></div></div>
                <span class="badge badge-active">Active</span>
            </div>
            <div style="background:var(--bg); padding:12px; border-radius:10px; border:1px solid var(--glass-border); font-size:0.85em; margin-bottom:12px;">
                <div style="margin-bottom:6px;"><i class="fas fa-envelope" style="color:var(--text-muted); width:20px;"></i> <?= htmlspecialchars($srv['email'] ?? '-') ?></div>
                <div><i class="fas fa-key" style="color:var(--text-muted); width:20px;"></i> <?= htmlspecialchars($srv['password'] ?? '-') ?></div>
            </div>
            <a href="<?= htmlspecialchars($pteroDomain) ?>" target="_blank" class="btn btn-primary btn-block" style="font-size:0.9em; padding:10px;"><i class="fas fa-external-link-alt"></i> Buka Panel Pterodactyl</a>
        </div>
    <?php endforeach; endif; ?>
    <a href="/logout.php" class="btn btn-block" style="background:rgba(239,68,68,0.1); color:var(--danger); margin-top:20px; border:1px solid var(--danger);"><i class="fas fa-sign-out-alt"></i> Logout</a>
</div>
<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

# --- CHAT PAGE ---
cat > "$WEB_ROOT/chat.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
requireLogin();
$pageTitle = 'Global Chat'; include __DIR__ . '/includes/header.php';
?>
<div class="container" style="max-width:700px;">
    <div class="card" style="padding:0; overflow:hidden; height:75vh; display:flex; flex-direction:column;">
        <div style="padding:15px 20px; border-bottom:1px solid var(--glass-border); background:var(--card); display:flex; align-items:center; gap:12px;">
            <div style="width:42px;height:42px;border-radius:50%;background:var(--gradient);display:flex;align-items:center;justify-content:center;color:#fff;font-size:1.1em;"><i class="fas fa-comments"></i></div>
            <div><div style="font-weight:700;">Global Chat</div><div style="font-size:0.8em; color:var(--success);"><i class="fas fa-circle" style="font-size:0.6em;"></i> Live</div></div>
        </div>
        <div id="chatBox" style="flex:1; overflow-y:auto; padding:20px; display:flex; flex-direction:column; gap:10px; background:rgba(0,0,0,0.2);"></div>
        <div style="padding:15px; border-top:1px solid var(--glass-border); display:flex; gap:10px; background:var(--card);">
            <input type="text" id="chatInput" placeholder="Ketik pesan..." style="flex:1; padding:12px 16px; border-radius:12px; border:1px solid var(--glass-border); background:var(--bg); color:var(--text); outline:none;">
            <button class="btn btn-primary" onclick="sendMsg()"><i class="fas fa-paper-plane"></i></button>
        </div>
    </div>
</div>
<script>
const chatBox = document.getElementById('chatBox'), chatInput = document.getElementById('chatInput');
const myUser = "<?= htmlspecialchars($_SESSION['username']) ?>";
async function loadChat() {
    const res = await fetch('/api/chat.php'); const data = await res.json();
    if (!data.ok) return;
    const isBottom = chatBox.scrollHeight - chatBox.scrollTop <= chatBox.clientHeight + 50;
    chatBox.innerHTML = data.chats.map(c => {
        const isMe = c.username === myUser;
        const isAdmin = c.is_admin == 1;
        const badge = isAdmin ? '<i class="fas fa-circle-check" style="color:#3b82f6;"></i>' : '';
        const bg = isMe ? 'var(--gradient)' : (isAdmin ? 'rgba(245,158,11,0.2)' : 'var(--bg)');
        const color = isMe ? '#fff' : 'var(--text)';
        const align = isMe ? 'flex-end' : 'flex-start';
        return `<div style="display:flex;flex-direction:column;align-items:${align};"><div style="font-size:0.75em;color:var(--text-muted);margin-bottom:2px;"><b style="color:${isAdmin?'var(--warning)':'var(--text-muted)'}">${c.username}</b> ${badge}</div><div style="background:${bg};color:${color};padding:10px 15px;border-radius:16px;max-width:80%;border:${isAdmin?'1px solid rgba(245,158,11,0.4)':'none'};">${c.message}</div></div>`;
    }).join('');
    if (isBottom) chatBox.scrollTop = chatBox.scrollHeight;
}
async function sendMsg() {
    const msg = chatInput.value.trim(); if (!msg) return;
    chatInput.value = '';
    await fetch('/api/chat.php', { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({ message: msg }) });
    loadChat(); chatBox.scrollTop = chatBox.scrollHeight;
}
chatInput.addEventListener('keypress', e => { if (e.key === 'Enter') sendMsg(); });
loadChat(); setInterval(loadChat, 2000);
</script>
<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

# --- CHAT API (Fix JSON Render) ---
cat > "$WEB_ROOT/api/chat.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
header('Content-Type: application/json');
if (!isLoggedIn()) { echo json_encode(['ok'=>false]); exit; }
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $s = $pdo->query("SELECT username, message, is_admin FROM chats ORDER BY id ASC LIMIT 50");
    echo json_encode(['ok'=>true,'chats'=>$s->fetchAll()]); exit;
}
$input = json_decode(file_get_contents('php://input'), true);
$msg = trim($input['message'] ?? '');
if ($msg) {
    $u = $pdo->prepare("SELECT username FROM users WHERE id=?"); $u->execute([$_SESSION['user_id']]); $user = $u->fetch();
    $pdo->prepare("INSERT INTO chats (user_id, username, message, is_admin) VALUES (?,?,?,?)")->execute([$_SESSION['user_id'], $user['username'], $msg, isAdmin() ? 1 : 0]);
    echo json_encode(['ok'=>true]);
} else { echo json_encode(['ok'=>false]); }
PHPEOF

# --- ADMIN PANEL ---
cat > "$WEB_ROOT/admin/index.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
requireAdmin();
$msg = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['save_api'])) {
        foreach (['ptero_domain', 'ptla', 'location_id', 'egg_id'] as $k) if (isset($_POST[$k])) $pdo->prepare("UPDATE settings SET v=? WHERE k=?")->execute([trim($_POST[$k]), $k]);
        $msg = 'API disimpan.';
    }
    if (isset($_POST['toggle_ban']) && isset($_POST['uid'])) {
        $uid = (int)$_POST['uid']; $new = $_POST['current_status'] === 'active' ? 'banned' : 'active';
        $pdo->prepare("UPDATE users SET status=? WHERE id=?")->execute([$new, $uid]); $msg = 'Status diubah.';
    }
    if (isset($_POST['delete_user']) && isset($_POST['uid'])) {
        $uid = (int)$_POST['uid'];
        $pdo->prepare("DELETE FROM users WHERE id=? AND role='user'")->execute([$uid]);
        $pdo->prepare("DELETE FROM servers WHERE user_id=?")->execute([$uid]); $msg = 'User dihapus.';
    }
    if (isset($_POST['delete_server']) && isset($_POST['srv_id']) && isset($_POST['ptero_id'])) {
        $srvId = (int)$_POST['srv_id']; $pteroId = (int)$_POST['ptero_id'];
        $pteroDomain = rtrim(getSetting($pdo, 'ptero_domain'), '/'); $ptla = getSetting($pdo, 'ptla');
        $ch = curl_init("$pteroDomain/api/application/servers/$pteroId");
        curl_setopt_array($ch, [CURLOPT_CUSTOMREQUEST => "DELETE", CURLOPT_RETURNTRANSFER => true, CURLOPT_HTTPHEADER => ["Authorization: Bearer $ptla"]]);
        curl_exec($ch); curl_close($ch);
        $pdo->prepare("DELETE FROM servers WHERE id=?")->execute([$srvId]); $msg = 'Server dihapus.';
    }
    if (isset($_POST['change_pw']) && isset($_POST['uid'])) {
        $uid = (int)$_POST['uid']; $newpw = trim($_POST['new_password']);
        if (strlen($newpw) >= 6) { $pdo->prepare("UPDATE users SET password=? WHERE id=?")->execute([password_hash($newpw, PASSWORD_BCRYPT), $uid]); $msg = 'Password diubah.'; }
        else { $msg = 'Password minimal 6 karakter.'; }
    }
    if (isset($_POST['broadcast'])) {
        $bc = trim($_POST['message']);
        if ($bc) { $pdo->prepare("INSERT INTO announcements (message) VALUES (?)")->execute([$bc]); $msg = 'Broadcast terkirim.'; }
    }
}
$totalUsers = $pdo->query("SELECT COUNT(*) FROM users WHERE role='user'")->fetchColumn();
$totalServers = $pdo->query("SELECT COUNT(*) FROM servers")->fetchColumn();
$totalRam = $pdo->query("SELECT SUM(ram) FROM servers")->fetchColumn() ?: 0;
$users = $pdo->query("SELECT * FROM users WHERE role='user' ORDER BY id DESC")->fetchAll();
$servers = $pdo->query("SELECT s.*, u.username FROM servers s JOIN users u ON s.user_id=u.id ORDER BY s.id DESC")->fetchAll();
$pageTitle = 'X-Admin';
include __DIR__ . '/../includes/header.php';
?>
<div class="container">
    <?php if ($msg): ?><div class="alert alert-success"><i class="fas fa-check-circle"></i> <?= $msg ?></div><?php endif; ?>
    <h1 style="margin-bottom:20px; font-size:1.6em;"><i class="fas fa-shield-halved" style="color:var(--warning)"></i> Admin Control</h1>

    <div style="display:grid; grid-template-columns:repeat(3,1fr); gap:12px; margin-bottom:20px;">
        <div class="card" style="text-align:center; padding:15px; margin:0;"><i class="fas fa-users" style="font-size:1.5em; color:var(--primary); margin-bottom:5px;"></i><div class="stat-value" data-count="<?= $totalUsers ?>">0</div><div class="stat-label">User</div></div>
        <div class="card" style="text-align:center; padding:15px; margin:0;"><i class="fas fa-server" style="font-size:1.5em; color:var(--success); margin-bottom:5px;"></i><div class="stat-value" data-count="<?= $totalServers ?>">0</div><div class="stat-label">Server</div></div>
        <div class="card" style="text-align:center; padding:15px; margin:0;"><i class="fas fa-memory" style="font-size:1.5em; color:var(--warning); margin-bottom:5px;"></i><div class="stat-value" data-count="<?= round($totalRam/1024, 1) ?>" data-suffix=" GB">0</div><div class="stat-label">RAM</div></div>
    </div>

    <div class="tabs">
        <button class="tab-btn active" onclick="showTab('api', event)"><i class="fas fa-cog"></i> API</button>
        <button class="tab-btn" onclick="showTab('users', event)"><i class="fas fa-users"></i> Users</button>
        <button class="tab-btn" onclick="showTab('servers', event)"><i class="fas fa-server"></i> Servers</button>
        <button class="tab-btn" onclick="showTab('bc', event)"><i class="fas fa-bullhorn"></i> Broadcast</button>
    </div>

    <div id="tab-api" class="tab-content active">
        <div class="card">
            <h2 style="margin-bottom:15px;"><i class="fas fa-cog"></i> API Pterodactyl</h2>
            <form method="POST">
                <input type="hidden" name="save_api" value="1">
                <div class="form-group"><label>Domain</label><input type="text" name="ptero_domain" value="<?= htmlspecialchars(getSetting($pdo, 'ptero_domain')) ?>" required></div>
                <div class="form-group"><label>PTLA</label><input type="text" name="ptla" value="<?= htmlspecialchars(getSetting($pdo, 'ptla')) ?>" required></div>
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                    <div class="form-group"><label>Location ID</label><input type="number" name="location_id" value="<?= htmlspecialchars(getSetting($pdo, 'location_id', '1')) ?>"></div>
                    <div class="form-group"><label>Egg ID</label><input type="number" name="egg_id" value="<?= htmlspecialchars(getSetting($pdo, 'egg_id', '15')) ?>"></div>
                </div>
                <button class="btn btn-primary"><i class="fas fa-save"></i> Simpan</button>
            </form>
        </div>
    </div>

    <div id="tab-users" class="tab-content">
        <?php foreach ($users as $u): ?>
            <div class="card" style="padding:16px;">
                <div style="display:flex; justify-content:space-between; align-items:flex-start; flex-wrap:wrap; gap:10px; margin-bottom:12px;">
                    <div><div style="font-weight:800;">@<?= htmlspecialchars($u['username']) ?></div><div style="font-size:0.8em; color:var(--text-muted);"><?= htmlspecialchars($u['email']) ?></div><span class="badge badge-<?= $u['status'] ?>" style="margin-top:5px; display:inline-block"><?= $u['status'] ?></span></div>
                    <div style="display:flex; gap:6px; flex-wrap:wrap;">
                        <form method="POST" style="margin:0;"><input type="hidden" name="uid" value="<?= $u['id'] ?>"><input type="hidden" name="current_status" value="<?= $u['status'] ?>"><button name="toggle_ban" class="btn btn-sm <?= $u['status']=='active'?'btn-danger':'btn-success' ?>" onclick="return confirm('Ubah status?')"><i class="fas fa-<?= $u['status']=='active'?'ban':'check' ?>"></i></button></form>
                        <form method="POST" style="margin:0;" onsubmit="return confirm('Hapus user?')"><input type="hidden" name="uid" value="<?= $u['id'] ?>"><button name="delete_user" class="btn btn-sm btn-danger"><i class="fas fa-trash"></i></button></form>
                    </div>
                </div>
                <form method="POST" style="display:flex; gap:6px;">
                    <input type="hidden" name="uid" value="<?= $u['id'] ?>">
                    <input type="text" name="new_password" placeholder="Password baru (min 6)" required style="flex:1; padding:8px 12px; border-radius:8px; border:1px solid var(--glass-border); background:var(--bg); color:var(--text); font-size:0.85em;">
                    <button name="change_pw" class="btn btn-sm btn-warning"><i class="fas fa-key"></i></button>
                </form>
            </div>
        <?php endforeach; ?>
    </div>

    <div id="tab-servers" class="tab-content">
        <?php foreach ($servers as $s): ?>
            <div class="card" style="padding:16px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;">
                <div><div style="font-weight:800;"><?= htmlspecialchars($s['server_name']) ?></div><div style="font-size:0.8em; color:var(--text-muted);">@<?= htmlspecialchars($s['username']) ?> • RAM: <?= $s['ram']==0?'Unlimited':$s['ram'].'MB' ?></div></div>
                <form method="POST" onsubmit="return confirm('Hapus server?')"><input type="hidden" name="srv_id" value="<?= $s['id'] ?>"><input type="hidden" name="ptero_id" value="<?= $s['ptero_id'] ?>"><button name="delete_server" class="btn btn-sm btn-danger"><i class="fas fa-trash"></i></button></form>
            </div>
        <?php endforeach; ?>
    </div>

    <div id="tab-bc" class="tab-content">
        <div class="card">
            <h2 style="margin-bottom:15px;"><i class="fas fa-bullhorn"></i> Broadcast</h2>
            <form method="POST"><input type="hidden" name="broadcast" value="1"><div class="form-group"><textarea name="message" rows="4" placeholder="Tulis pengumuman..." required></textarea></div><button class="btn btn-primary btn-block"><i class="fas fa-paper-plane"></i> Kirim</button></form>
        </div>
    </div>
</div>
<script>
function showTab(name, event) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    event.currentTarget.classList.add('active'); // FIX: event.currentTarget
}
document.querySelectorAll('.stat-value').forEach(el => {
    const target = parseFloat(el.dataset.count);
    const suffix = el.dataset.suffix || '';
    let current = 0;
    const step = target / 30;
    const timer = setInterval(() => {
        current += step;
        if (current >= target) { current = target; clearInterval(timer); }
        el.textContent = Math.round(current) + suffix;
    }, 30);
});
</script>
<?php include __DIR__ . '/../includes/footer.php'; ?>
PHPEOF

# --- LOGOUT ---
cat > "$WEB_ROOT/logout.php" << 'PHPEOF'
<?php session_start(); session_destroy(); header('Location: /login.php'); exit;
PHPEOF

echo -e "${GREEN}  ✅ Semua Halaman OK${NC}\n"

# ============================================
# NGINX & SSL
# ============================================
echo -e "${CYAN}[7/7] Setup Nginx & SSL...${NC}"
cat > "$NGINX_CONF" << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    root $WEB_ROOT;
    index index.php index.html;

    # Blokir akses ke folder konfigurasi
    location ~ /includes/ { deny all; }

    location / { try_files \$uri \$uri/ =404; }
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    }
}
NGINXEOF

ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/ 2>/dev/null
# HAPUS PEMAKSAAN HAPUS DEFAULT. Biarkan jika ada website lain.
nginx -t >/dev/null 2>&1 && systemctl reload nginx

chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"
systemctl restart php8.3-fpm

SERVER_IP=$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null)
DOMAIN_IP=$(dig +short A "$DOMAIN" @8.8.8.8 2>/dev/null | head -1)
if [[ "$SERVER_IP" == "$DOMAIN_IP" ]]; then
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect >/dev/null 2>&1
fi

PROTO="https"; [[ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]] && PROTO="http"

# ============ HASIL AKHIR ============
clear
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ INSTALLASI BERHASIL!                   ║${NC}"
echo -e "${GREEN}║  👑 RENDZZ RESELLER v16.1                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}🔗 URL Web:${NC} $PROTO://$DOMAIN"
echo -e "${MAGENTA}🔒 Admin Panel:${NC} $PROTO://$DOMAIN/admin/"
echo ""
echo -e "${WHITE}🔑 Admin Secret:${NC}"
echo -e "   Username : ${WHITE}aulia${NC}"
echo -e "   Password : ${WHITE}aulia55${NC}"
echo -e "   ${YELLOW}(Jangan share kredensial ini!)${NC}"
echo ""
echo -e "${CYAN}📌 Fitur Lengkap:${NC}"
echo -e "  ✅ Auto Install & Fix Lock (Aman)"
echo -e "  ✅ Landing Page Scrollable (Hero, Stats, Fitur, Cara Kerja, Testimoni, FAQ, CTA)"
echo -e "  ✅ Live Stats Animation"
echo -e "  ✅ Dark/Light Theme Toggle"
echo -e "  ✅ Hamburger Menu Navigasi"
echo -e "  ✅ Dashboard Deploy Server (RAM 1GB - Unlimited)"
echo -e "  ✅ Profile & My Server"
echo -e "  ✅ Global Chat (Centang Biru Admin)"
echo -e "  ✅ Admin Panel Super (Ban, Hapus User, Hapus Server, Ganti PW, Broadcast)"
echo -e "  ✅ Bottom Nav & Copyright"
echo ""
echo -e "${GREEN}🚀 Buka webnya, login admin 'aulia', setting API Pterodactyl!${NC}"
