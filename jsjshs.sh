#!/bin/bash
# ============================================
#   👑 RENDZZ ULTIMATE v13.0 — FULL UPDATE
#   Hamburger Menu • Admin Super • All Icons
# ============================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}❌ Harus root!${NC}"; exit 1; }

clear
echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  👑 RENDZZ ULTIMATE v13.0 — FULL UPDATE    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
echo ""

read -p "👉 Subdomain Web (contoh: panel.domain.com): " DOMAIN
WEB_ROOT="/var/www/$DOMAIN"

if [ ! -d "$WEB_ROOT" ]; then
    echo -e "${RED}❌ Folder web tidak ditemukan!${NC}"
    exit 1
fi

DB_NAME=$(grep "DB_NAME" "$WEB_ROOT/includes/config.php" | grep -oP "'\K[^']+" | tail -1)

# ============ 1. UPDATE DATABASE ============
echo -e "${CYAN}[1/5] Update Database...${NC}"
mysql "$DB_NAME" << 'SQLEOF' 2>/dev/null
ALTER TABLE users ADD COLUMN IF NOT EXISTS status ENUM('active','banned') DEFAULT 'active';
SQLEOF
echo -e "${GREEN}  ✅ Database OK${NC}"

# ============ 2. UPDATE CSS (PRO MAX) ============
echo -e "${CYAN}[2/5] Update CSS...${NC}"

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
    background: var(--bg);
    background-image: var(--bg-gradient);
    background-attachment: fixed;
    color: var(--text);
    min-height: 100vh;
    padding-top: 70px;
    padding-bottom: 80px;
    -webkit-font-smoothing: antialiased;
}

a { color: inherit; text-decoration: none; }
.container { max-width: 800px; margin: 0 auto; padding: 20px; }

/* NAVBAR TOP (Hamburger + Brand + Theme) */
.top-nav {
    position: fixed;
    top: 0; left: 0; right: 0;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 20px;
    background: rgba(10, 10, 20, 0.85);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    border-bottom: 1px solid var(--glass-border);
    z-index: 9998;
}

[data-theme="light"] .top-nav { background: rgba(255,255,255,0.85); }

.brand {
    font-size: 1.2em;
    font-weight: 800;
    background: var(--gradient);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    display: flex;
    align-items: center;
    gap: 8px;
}

.nav-actions { display: flex; gap: 8px; }

.nav-btn {
    width: 40px; height: 40px;
    border-radius: 12px;
    background: var(--card);
    border: 1px solid var(--glass-border);
    color: var(--text);
    font-size: 1.1em;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.3s;
}

.nav-btn:hover { border-color: var(--primary); color: var(--primary); }

/* SIDEBAR MENU */
.sidebar-overlay {
    position: fixed; inset: 0;
    background: rgba(0, 0, 0, 0.7);
    backdrop-filter: blur(5px);
    z-index: 9999;
    opacity: 0;
    visibility: hidden;
    transition: all 0.3s;
}

.sidebar-overlay.active { opacity: 1; visibility: visible; }

.sidebar {
    position: fixed;
    top: 0; left: -320px;
    width: 300px; height: 100vh;
    background: var(--card);
    backdrop-filter: blur(20px);
    border-right: 1px solid var(--glass-border);
    z-index: 10000;
    transition: left 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    overflow-y: auto;
}

.sidebar.open { left: 0; }

.sidebar-header {
    padding: 20px;
    border-bottom: 1px solid var(--glass-border);
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.sidebar-title {
    font-size: 1.1em;
    font-weight: 800;
    background: var(--gradient);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}

.sidebar-nav { padding: 15px; }

.sidebar-label {
    font-size: 0.7em;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 1.5px;
    font-weight: 700;
    padding: 15px 15px 8px;
}

.sidebar-link {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 15px;
    border-radius: 12px;
    color: var(--text);
    font-weight: 600;
    font-size: 0.95em;
    transition: all 0.2s;
    margin-bottom: 2px;
}

.sidebar-link:hover {
    background: rgba(99, 102, 241, 0.1);
    color: var(--primary);
    transform: translateX(4px);
}

.sidebar-link i {
    width: 22px;
    text-align: center;
    font-size: 1.1em;
    color: var(--text-muted);
}

.sidebar-link:hover i { color: var(--primary); }

/* CARD */
.card {
    background: var(--card);
    backdrop-filter: blur(20px);
    border: 1px solid var(--glass-border);
    border-radius: 20px;
    padding: 24px;
    margin-bottom: 20px;
    transition: all 0.3s;
    animation: slideUp 0.5s ease-out;
}

@keyframes slideUp {
    from { opacity: 0; transform: translateY(20px); }
    to { opacity: 1; transform: translateY(0); }
}

/* BUTTONS */
.btn {
    padding: 12px 20px;
    border-radius: 12px;
    border: none;
    font-weight: 700;
    font-family: inherit;
    font-size: 0.9em;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    transition: all 0.3s;
    text-decoration: none;
}

.btn-primary { background: var(--gradient); color: #fff; box-shadow: 0 4px 15px var(--primary-glow); }
.btn-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 25px var(--primary-glow); }

.btn-danger { background: rgba(239, 68, 68, 0.15); color: var(--danger); border: 1px solid var(--danger); }
.btn-danger:hover { background: var(--danger); color: #fff; }

.btn-success { background: rgba(16, 185, 129, 0.15); color: var(--success); border: 1px solid var(--success); }
.btn-success:hover { background: var(--success); color: #fff; }

.btn-warning { background: rgba(245, 158, 11, 0.15); color: var(--warning); border: 1px solid var(--warning); }
.btn-warning:hover { background: var(--warning); color: #fff; }

.btn-block { width: 100%; }
.btn-sm { padding: 8px 12px; font-size: 0.8em; border-radius: 8px; }

/* FORMS */
.form-group { margin-bottom: 16px; }
.form-group label {
    display: block;
    margin-bottom: 8px;
    font-size: 0.85em;
    color: var(--text-muted);
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}
.form-group input, .form-group select, .form-group textarea {
    width: 100%;
    padding: 12px 16px;
    border: 1px solid var(--glass-border);
    border-radius: 12px;
    background: rgba(0, 0, 0, 0.3);
    color: var(--text);
    font-family: inherit;
    font-size: 0.95em;
    outline: none;
    transition: all 0.2s;
}
.form-group input:focus, .form-group select:focus, .form-group textarea:focus {
    border-color: var(--primary);
    box-shadow: 0 0 0 3px var(--primary-glow);
}

/* ALERTS */
.alert { padding: 14px 18px; border-radius: 12px; margin-bottom: 16px; font-size: 0.9em; font-weight: 600; display: flex; align-items: center; gap: 10px; }
.alert-error { background: rgba(239, 68, 68, 0.15); color: var(--danger); border: 1px solid rgba(239, 68, 68, 0.3); }
.alert-success { background: rgba(16, 185, 129, 0.15); color: var(--success); border: 1px solid rgba(16, 185, 129, 0.3); }

/* BADGES */
.badge { padding: 4px 10px; border-radius: 6px; font-size: 0.75em; font-weight: 800; text-transform: uppercase; }
.badge-active { background: rgba(16, 185, 129, 0.15); color: var(--success); }
.badge-banned { background: rgba(239, 68, 68, 0.15); color: var(--danger); }

/* TABLES */
.table { width: 100%; border-collapse: collapse; font-size: 0.85em; }
.table th, .table td { padding: 12px 8px; text-align: left; border-bottom: 1px solid var(--glass-border); }
.table th { color: var(--text-muted); font-size: 0.75em; text-transform: uppercase; font-weight: 700; }

/* BOTTOM NAV */
.bottom-nav {
    position: fixed;
    bottom: 15px; left: 15px; right: 15px;
    background: var(--card);
    backdrop-filter: blur(20px);
    border: 1px solid var(--glass-border);
    border-radius: 24px;
    display: flex;
    justify-content: space-around;
    padding: 10px 0;
    z-index: 9997;
    max-width: 500px;
    margin: 0 auto;
    box-shadow: 0 10px 40px rgba(0,0,0,0.3);
}

.nav-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    color: var(--text-muted);
    font-size: 0.7em;
    font-weight: 700;
    padding: 8px 16px;
    border-radius: 16px;
    transition: all 0.3s;
}

.nav-item i { font-size: 1.4em; }
.nav-item:hover, .nav-item.active { color: var(--primary); background: rgba(99, 102, 241, 0.15); transform: translateY(-4px); }

/* TABS */
.tabs {
    display: flex;
    gap: 8px;
    margin-bottom: 20px;
    overflow-x: auto;
    padding-bottom: 5px;
}

.tab-btn {
    padding: 10px 18px;
    border-radius: 12px;
    border: 1px solid var(--glass-border);
    background: var(--card);
    color: var(--text-muted);
    cursor: pointer;
    font-weight: 700;
    font-size: 0.85em;
    white-space: nowrap;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    gap: 6px;
}

.tab-btn.active { background: var(--gradient); color: #fff; border-color: transparent; }
.tab-content { display: none; }
.tab-content.active { display: block; animation: slideUp 0.3s; }

/* FOOTER */
.copyright { text-align: center; padding: 30px 20px; font-size: 0.8em; color: var(--text-muted); margin-top: 30px; }
.copyright span { background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; font-weight: 800; }

@media(max-width: 600px) {
    .container { padding: 15px; }
    .card { padding: 18px; }
}
CSSEOF
echo -e "${GREEN}  ✅ CSS OK${NC}"

# ============ 3. UPDATE HEADER (HAMBURGER + SIDEBAR) ============
echo -e "${CYAN}[3/5] Update Header (Hamburger & Sidebar)...${NC}"

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
<script>
document.documentElement.setAttribute('data-theme', localStorage.getItem('theme') || 'dark');
</script>
</head>
<body>

<!-- TOP NAVBAR -->
<div class="top-nav">
    <div class="brand"><i class="fas fa-bolt"></i> RendzzPanel</div>
    <div class="nav-actions">
        <button class="nav-btn" onclick="toggleSidebar()" title="Menu"><i class="fas fa-bars"></i></button>
        <button class="nav-btn" onclick="toggleTheme()" title="Tema"><i class="fas fa-moon" id="themeIcon"></i></button>
    </div>
</div>

<!-- SIDEBAR MENU -->
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
    const current = document.documentElement.getAttribute('data-theme');
    const next = current === 'dark' ? 'light' : 'dark';
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
echo -e "${GREEN}  ✅ Header OK${NC}"

# ============ 4. UPDATE ADMIN PANEL (FULL CONTROL) ============
echo -e "${CYAN}[4/5] Update Admin Panel Super...${NC}"

cat > "$WEB_ROOT/admin/index.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
requireAdmin();
$msg = '';

// API SETTINGS
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['save_api'])) {
    foreach (['ptero_domain', 'ptla', 'location_id', 'egg_id'] as $k) {
        if (isset($_POST[$k])) $pdo->prepare("UPDATE settings SET v=? WHERE k=?")->execute([trim($_POST[$k]), $k]);
    }
    $msg = 'API berhasil disimpan.';
}

// BAN / UNBAN
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['toggle_ban'])) {
    $uid = (int)$_POST['uid']; $new = $_POST['current_status'] === 'active' ? 'banned' : 'active';
    $pdo->prepare("UPDATE users SET status=? WHERE id=?")->execute([$new, $uid]);
    $msg = 'Status user diubah.';
}

// DELETE USER
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete_user'])) {
    $uid = (int)$_POST['uid'];
    $pdo->prepare("DELETE FROM users WHERE id=? AND role='user'")->execute([$uid]);
    $pdo->prepare("DELETE FROM servers WHERE user_id=?")->execute([$uid]);
    $msg = 'User berhasil dihapus.';
}

// DELETE SERVER
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete_server'])) {
    $srvId = (int)$_POST['srv_id']; $pteroId = (int)$_POST['ptero_id'];
    $pteroDomain = rtrim(getSetting($pdo, 'ptero_domain'), '/'); $ptla = getSetting($pdo, 'ptla');
    $ch = curl_init("$pteroDomain/api/application/servers/$pteroId");
    curl_setopt_array($ch, [CURLOPT_CUSTOMREQUEST => "DELETE", CURLOPT_RETURNTRANSFER => true, CURLOPT_HTTPHEADER => ["Authorization: Bearer $ptla"]]);
    curl_exec($ch); curl_close($ch);
    $pdo->prepare("DELETE FROM servers WHERE id=?")->execute([$srvId]);
    $msg = 'Server berhasil dihapus.';
}

// CHANGE PASSWORD
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['change_pw'])) {
    $uid = (int)$_POST['uid']; $newpw = trim($_POST['new_password']);
    if (strlen($newpw) >= 6) {
        $hash = password_hash($newpw, PASSWORD_BCRYPT);
        $pdo->prepare("UPDATE users SET password=? WHERE id=?")->execute([$hash, $uid]);
        $msg = 'Password user berhasil diubah.';
    } else {
        $msg = 'Password minimal 6 karakter.';
    }
}

// BROADCAST
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['broadcast'])) {
    $bc = trim($_POST['message']);
    if ($bc) { $pdo->prepare("INSERT INTO announcements (message) VALUES (?)")->execute([$bc]); $msg = 'Broadcast terkirim.'; }
}

// STATISTIK
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

    <h1 style="margin-bottom:20px; font-size:1.8em;"><i class="fas fa-shield-halved" style="color:var(--warning)"></i> Admin Control Center</h1>

    <!-- STATISTIK -->
    <div style="display:grid; grid-template-columns:repeat(3,1fr); gap:12px; margin-bottom:20px;">
        <div class="card" style="text-align:center; padding:15px; margin:0;">
            <i class="fas fa-users" style="font-size:1.5em; color:var(--primary); margin-bottom:5px;"></i>
            <div style="font-size:1.5em; font-weight:800;"><?= $totalUsers ?></div>
            <div style="font-size:0.7em; color:var(--text-muted); text-transform:uppercase;">User</div>
        </div>
        <div class="card" style="text-align:center; padding:15px; margin:0;">
            <i class="fas fa-server" style="font-size:1.5em; color:var(--success); margin-bottom:5px;"></i>
            <div style="font-size:1.5em; font-weight:800;"><?= $totalServers ?></div>
            <div style="font-size:0.7em; color:var(--text-muted); text-transform:uppercase;">Server</div>
        </div>
        <div class="card" style="text-align:center; padding:15px; margin:0;">
            <i class="fas fa-memory" style="font-size:1.5em; color:var(--warning); margin-bottom:5px;"></i>
            <div style="font-size:1.5em; font-weight:800;"><?= round($totalRam/1024, 1) ?> GB</div>
            <div style="font-size:0.7em; color:var(--text-muted); text-transform:uppercase;">RAM</div>
        </div>
    </div>

    <!-- TABS -->
    <div class="tabs">
        <button class="tab-btn active" onclick="showTab('api')"><i class="fas fa-cog"></i> API</button>
        <button class="tab-btn" onclick="showTab('users')"><i class="fas fa-users"></i> Users</button>
        <button class="tab-btn" onclick="showTab('servers')"><i class="fas fa-server"></i> Servers</button>
        <button class="tab-btn" onclick="showTab('bc')"><i class="fas fa-bullhorn"></i> Broadcast</button>
    </div>

    <!-- TAB API -->
    <div id="tab-api" class="tab-content active">
        <div class="card">
            <h2 style="margin-bottom:15px;"><i class="fas fa-cog"></i> Setting Pterodactyl API</h2>
            <form method="POST">
                <input type="hidden" name="save_api" value="1">
                <div class="form-group"><label>Domain Pterodactyl</label><input type="text" name="ptero_domain" value="<?= htmlspecialchars(getSetting($pdo, 'ptero_domain')) ?>" required></div>
                <div class="form-group"><label>PTLA (API Key)</label><input type="text" name="ptla" value="<?= htmlspecialchars(getSetting($pdo, 'ptla')) ?>" required></div>
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                    <div class="form-group"><label>Location ID</label><input type="number" name="location_id" value="<?= htmlspecialchars(getSetting($pdo, 'location_id', '1')) ?>"></div>
                    <div class="form-group"><label>Egg ID</label><input type="number" name="egg_id" value="<?= htmlspecialchars(getSetting($pdo, 'egg_id', '15')) ?>"></div>
                </div>
                <button class="btn btn-primary"><i class="fas fa-save"></i> Simpan API</button>
            </form>
        </div>
    </div>

    <!-- TAB USERS -->
    <div id="tab-users" class="tab-content">
        <?php foreach ($users as $u): ?>
            <div class="card" style="padding:16px;">
                <div style="display:flex; justify-content:space-between; align-items:flex-start; flex-wrap:wrap; gap:10px; margin-bottom:12px;">
                    <div>
                        <div style="font-weight:800; font-size:1.05em;">@<?= htmlspecialchars($u['username']) ?></div>
                        <div style="font-size:0.8em; color:var(--text-muted);"><?= htmlspecialchars($u['email']) ?></div>
                        <span class="badge badge-<?= $u['status'] ?>" style="margin-top:5px; display:inline-block"><?= $u['status'] ?></span>
                    </div>
                    <div style="display:flex; gap:6px; flex-wrap:wrap;">
                        <form method="POST" style="margin:0;"><input type="hidden" name="uid" value="<?= $u['id'] ?>"><input type="hidden" name="current_status" value="<?= $u['status'] ?>"><button name="toggle_ban" class="btn btn-sm <?= $u['status']=='active'?'btn-danger':'btn-success' ?>" onclick="return confirm('Ubah status?')"><i class="fas fa-<?= $u['status']=='active'?'ban':'check' ?>"></i></button></form>
                        <form method="POST" style="margin:0;" onsubmit="return confirm('Hapus user ini permanen?')"><input type="hidden" name="uid" value="<?= $u['id'] ?>"><button name="delete_user" class="btn btn-sm btn-danger"><i class="fas fa-trash"></i></button></form>
                    </div>
                </div>
                <form method="POST" style="display:flex; gap:6px;">
                    <input type="hidden" name="uid" value="<?= $u['id'] ?>">
                    <input type="text" name="new_password" placeholder="Password baru (min 6)" required style="flex:1; padding:8px 12px; border-radius:8px; border:1px solid var(--glass-border); background:var(--bg); color:var(--text); font-size:0.85em;">
                    <button name="change_pw" class="btn btn-sm btn-warning"><i class="fas fa-key"></i> Ganti</button>
                </form>
            </div>
        <?php endforeach; ?>
        <?php if (empty($users)): ?><p style="text-align:center; color:var(--text-muted);">Belum ada user.</p><?php endif; ?>
    </div>

    <!-- TAB SERVERS -->
    <div id="tab-servers" class="tab-content">
        <?php foreach ($servers as $s): ?>
            <div class="card" style="padding:16px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;">
                <div>
                    <div style="font-weight:800; font-size:1.05em;"><?= htmlspecialchars($s['server_name']) ?></div>
                    <div style="font-size:0.8em; color:var(--text-muted);"><i class="fas fa-user"></i> @<?= htmlspecialchars($s['username']) ?> • <i class="fas fa-memory"></i> <?= $s['ram']==0?'Unlimited':$s['ram'].'MB' ?></div>
                </div>
                <form method="POST" onsubmit="return confirm('Hapus server ini?')">
                    <input type="hidden" name="srv_id" value="<?= $s['id'] ?>">
                    <input type="hidden" name="ptero_id" value="<?= $s['ptero_id'] ?>">
                    <button name="delete_server" class="btn btn-sm btn-danger"><i class="fas fa-trash"></i> Hapus</button>
                </form>
            </div>
        <?php endforeach; ?>
        <?php if (empty($servers)): ?><p style="text-align:center; color:var(--text-muted);">Belum ada server.</p><?php endif; ?>
    </div>

    <!-- TAB BROADCAST -->
    <div id="tab-bc" class="tab-content">
        <div class="card">
            <h2 style="margin-bottom:15px;"><i class="fas fa-bullhorn"></i> Broadcast</h2>
            <form method="POST">
                <input type="hidden" name="broadcast" value="1">
                <div class="form-group"><textarea name="message" rows="4" placeholder="Contoh: Server akan maintenance jam 12 malam..." required></textarea></div>
                <button class="btn btn-primary btn-block"><i class="fas fa-paper-plane"></i> Kirim ke Semua User</button>
            </form>
        </div>
    </div>
</div>

<script>
function showTab(name) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    event.target.closest('.tab-btn').classList.add('active');
}
</script>
<?php include __DIR__ . '/../includes/footer.php'; ?>
PHPEOF
echo -e "${GREEN}  ✅ Admin Panel Super OK${NC}"

# ============ 5. UPDATE DASHBOARD (RAM UNLIMITED + ICONS) ============
echo -e "${CYAN}[5/5] Update Dashboard...${NC}"

# Update dashboard.php bagian form RAM
if [ -f "$WEB_ROOT/dashboard.php" ]; then
    # Pastikan form RAM ada Unlimited
    sed -i 's|<option value="0">Unlimited (∞)</option>|<option value="0">Unlimited (RAM Tanpa Batas)</option>|g' "$WEB_ROOT/dashboard.php" 2>/dev/null
fi

# Restart
chown -R www-data:www-data "$WEB_ROOT"
systemctl restart php8.3-fpm

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ ULTIMATE v13.0 BERHASIL DI-INSTALL!    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📌 Fitur Baru:${NC}"
echo -e "  ☰ Menu Garis 3 (Hamburger) di atas"
echo -e "  🌓 Theme Toggle (Dark/Light) di atas"
echo -e "  👤 Admin: Hapus User, Hapus Server, Ganti Password"
echo -e "  🚫 Admin: Ban/Unban User"
echo -e "  📢 Admin: Broadcast"
echo -e "  ♾️  RAM Unlimited di Dashboard User"
echo -e "  🎨 Semua Icon pakai FontAwesome (bukan emoji)"
echo ""
echo -e "${GREEN}🚀 Refresh browser (CTRL + SHIFT + R)!${NC}"
