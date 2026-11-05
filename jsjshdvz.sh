#!/bin/bash
# ============================================
#   👑 RENDZZ ULTIMATE v14.0 — THE BIG UPDATE
#   Live Stats • Modern Tabs • All Icons
# ============================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}❌ Harus root!${NC}"; exit 1; }

clear
echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  👑 RENDZZ ULTIMATE v14.0 — UPDATE         ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
echo ""

read -p "👉 Subdomain Web (contoh: panel.domain.com): " DOMAIN
WEB_ROOT="/var/www/$DOMAIN"

if [ ! -d "$WEB_ROOT" ]; then
    echo -e "${RED}❌ Folder web tidak ditemukan!${NC}"
    exit 1
fi

# ============ 1. UPDATE CSS (PRO MAX v14) ============
echo -e "${CYAN}[1/5] Update CSS v14.0...${NC}"

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

/* NAVBAR */
.top-nav {
    position: fixed; top: 0; left: 0; right: 0;
    display: flex; justify-content: space-between; align-items: center;
    padding: 12px 20px;
    background: rgba(10, 10, 20, 0.85);
    backdrop-filter: blur(20px);
    border-bottom: 1px solid var(--glass-border);
    z-index: 9998;
}
[data-theme="light"] .top-nav { background: rgba(255,255,255,0.85); }

.brand {
    font-size: 1.2em; font-weight: 800;
    background: var(--gradient);
    -webkit-background-clip: text; -webkit-text-fill-color: transparent;
    display: flex; align-items: center; gap: 8px;
}

.nav-actions { display: flex; gap: 8px; }
.nav-btn {
    width: 40px; height: 40px;
    border-radius: 12px;
    background: var(--card);
    border: 1px solid var(--glass-border);
    color: var(--text); font-size: 1.1em;
    cursor: pointer;
    display: flex; align-items: center; justify-content: center;
    transition: all 0.3s;
}
.nav-btn:hover { border-color: var(--primary); color: var(--primary); }

/* SIDEBAR */
.sidebar-overlay {
    position: fixed; inset: 0;
    background: rgba(0, 0, 0, 0.7);
    backdrop-filter: blur(5px);
    z-index: 9999; opacity: 0; visibility: hidden;
    transition: all 0.3s;
}
.sidebar-overlay.active { opacity: 1; visibility: visible; }

.sidebar {
    position: fixed; top: 0; left: -320px;
    width: 300px; height: 100vh;
    background: var(--card); backdrop-filter: blur(20px);
    border-right: 1px solid var(--glass-border);
    z-index: 10000;
    transition: left 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    overflow-y: auto;
}
.sidebar.open { left: 0; }

.sidebar-header {
    padding: 20px; border-bottom: 1px solid var(--glass-border);
    display: flex; justify-content: space-between; align-items: center;
}
.sidebar-title {
    font-size: 1.1em; font-weight: 800;
    background: var(--gradient);
    -webkit-background-clip: text; -webkit-text-fill-color: transparent;
}

.sidebar-nav { padding: 15px; }
.sidebar-label {
    font-size: 0.7em; color: var(--text-muted);
    text-transform: uppercase; letter-spacing: 1.5px;
    font-weight: 700; padding: 15px 15px 8px;
}
.sidebar-link {
    display: flex; align-items: center; gap: 12px;
    padding: 12px 15px; border-radius: 12px;
    color: var(--text); font-weight: 600; font-size: 0.95em;
    transition: all 0.2s; margin-bottom: 2px;
}
.sidebar-link:hover { background: rgba(99, 102, 241, 0.1); color: var(--primary); transform: translateX(4px); }
.sidebar-link i { width: 22px; text-align: center; font-size: 1.1em; color: var(--text-muted); }
.sidebar-link:hover i { color: var(--primary); }

/* CARD */
.card {
    background: var(--card); backdrop-filter: blur(20px);
    border: 1px solid var(--glass-border);
    border-radius: 20px; padding: 24px;
    margin-bottom: 20px; transition: all 0.3s;
    animation: slideUp 0.5s ease-out;
}
@keyframes slideUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

/* BUTTONS */
.btn {
    padding: 12px 20px; border-radius: 12px; border: none;
    font-weight: 700; font-family: inherit; font-size: 0.9em;
    cursor: pointer; display: inline-flex; align-items: center; justify-content: center;
    gap: 8px; transition: all 0.3s; text-decoration: none;
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
    display: block; margin-bottom: 8px; font-size: 0.85em;
    color: var(--text-muted); font-weight: 600;
    text-transform: uppercase; letter-spacing: 0.5px;
}
.form-group input, .form-group select, .form-group textarea {
    width: 100%; padding: 12px 16px;
    border: 1px solid var(--glass-border); border-radius: 12px;
    background: rgba(0, 0, 0, 0.3); color: var(--text);
    font-family: inherit; font-size: 0.95em;
    outline: none; transition: all 0.2s;
}
.form-group input:focus, .form-group select:focus, .form-group textarea:focus {
    border-color: var(--primary); box-shadow: 0 0 0 3px var(--primary-glow);
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
    position: fixed; bottom: 15px; left: 15px; right: 15px;
    background: var(--card); backdrop-filter: blur(20px);
    border: 1px solid var(--glass-border); border-radius: 24px;
    display: flex; justify-content: space-around; padding: 10px 0;
    z-index: 9997; max-width: 500px; margin: 0 auto;
    box-shadow: 0 10px 40px rgba(0,0,0,0.3);
}
.nav-item {
    display: flex; flex-direction: column; align-items: center;
    gap: 4px; color: var(--text-muted); font-size: 0.7em;
    font-weight: 700; padding: 8px 16px; border-radius: 16px;
    transition: all 0.3s;
}
.nav-item i { font-size: 1.4em; }
.nav-item:hover, .nav-item.active { color: var(--primary); background: rgba(99, 102, 241, 0.15); transform: translateY(-4px); }

/* MODERN TABS (PILL) */
.tabs {
    display: flex; gap: 8px; margin-bottom: 20px;
    overflow-x: auto; padding: 6px;
    background: rgba(0,0,0,0.2); border-radius: 16px;
    border: 1px solid var(--glass-border);
}
.tab-btn {
    padding: 10px 18px; border-radius: 12px; border: none;
    background: transparent; color: var(--text-muted);
    cursor: pointer; font-weight: 700; font-size: 0.85em;
    white-space: nowrap; transition: all 0.3s;
    display: flex; align-items: center; gap: 6px;
}
.tab-btn.active { background: var(--gradient); color: #fff; box-shadow: 0 4px 15px var(--primary-glow); }
.tab-content { display: none; }
.tab-content.active { display: block; animation: slideUp 0.3s; }

/* STATS ANIMATED */
.stat-box { text-align: center; padding: 20px 10px; }
.stat-value { font-size: 2em; font-weight: 800; background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; display: block; line-height: 1.2; }
.stat-label { font-size: 0.7em; color: var(--text-muted); text-transform: uppercase; letter-spacing: 1px; font-weight: 700; margin-top: 4px; }

/* CHART */
.chart-container { height: 180px; position: relative; margin: 20px 0; }

/* FOOTER */
.copyright { text-align: center; padding: 30px 20px; font-size: 0.8em; color: var(--text-muted); margin-top: 30px; }
.copyright span { background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; font-weight: 800; }

@media(max-width: 600px) { .container { padding: 15px; } .card { padding: 18px; } }
CSSEOF
echo -e "${GREEN}  ✅ CSS OK${NC}"

# ============ 2. UPDATE ADMIN PANEL ============
echo -e "${CYAN}[2/5] Update Admin Panel...${NC}"

cat > "$WEB_ROOT/admin/index.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
requireAdmin();
$msg = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['save_api'])) {
        foreach (['ptero_domain', 'ptla', 'location_id', 'egg_id'] as $k) {
            if (isset($_POST[$k])) $pdo->prepare("UPDATE settings SET v=? WHERE k=?")->execute([trim($_POST[$k]), $k]);
        }
        $msg = 'API berhasil disimpan.';
    }
    if (isset($_POST['toggle_ban'])) {
        $uid = (int)$_POST['uid']; $new = $_POST['current_status'] === 'active' ? 'banned' : 'active';
        $pdo->prepare("UPDATE users SET status=? WHERE id=?")->execute([$new, $uid]);
        $msg = 'Status user diubah.';
    }
    if (isset($_POST['delete_user'])) {
        $uid = (int)$_POST['uid'];
        $pdo->prepare("DELETE FROM users WHERE id=? AND role='user'")->execute([$uid]);
        $pdo->prepare("DELETE FROM servers WHERE user_id=?")->execute([$uid]);
        $msg = 'User berhasil dihapus.';
    }
    if (isset($_POST['delete_server'])) {
        $srvId = (int)$_POST['srv_id']; $pteroId = (int)$_POST['ptero_id'];
        $pteroDomain = rtrim(getSetting($pdo, 'ptero_domain'), '/'); $ptla = getSetting($pdo, 'ptla');
        $ch = curl_init("$pteroDomain/api/application/servers/$pteroId");
        curl_setopt_array($ch, [CURLOPT_CUSTOMREQUEST => "DELETE", CURLOPT_RETURNTRANSFER => true, CURLOPT_HTTPHEADER => ["Authorization: Bearer $ptla"]]);
        curl_exec($ch); curl_close($ch);
        $pdo->prepare("DELETE FROM servers WHERE id=?")->execute([$srvId]);
        $msg = 'Server berhasil dihapus.';
    }
    if (isset($_POST['change_pw'])) {
        $uid = (int)$_POST['uid']; $newpw = trim($_POST['new_password']);
        if (strlen($newpw) >= 6) {
            $pdo->prepare("UPDATE users SET password=? WHERE id=?")->execute([password_hash($newpw, PASSWORD_BCRYPT), $uid]);
            $msg = 'Password user berhasil diubah.';
        } else { $msg = 'Password minimal 6 karakter.'; }
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

    <h1 style="margin-bottom:20px; font-size:1.6em;"><i class="fas fa-shield-halved" style="color:var(--warning)"></i> Admin Control Center</h1>

    <!-- STATS -->
    <div style="display:grid; grid-template-columns:repeat(3,1fr); gap:12px; margin-bottom:20px;">
        <div class="card stat-box" style="margin:0;">
            <i class="fas fa-users" style="font-size:1.5em; color:var(--primary); margin-bottom:5px;"></i>
            <span class="stat-value" data-count="<?= $totalUsers ?>">0</span>
            <div class="stat-label">User</div>
        </div>
        <div class="card stat-box" style="margin:0;">
            <i class="fas fa-server" style="font-size:1.5em; color:var(--success); margin-bottom:5px;"></i>
            <span class="stat-value" data-count="<?= $totalServers ?>">0</span>
            <div class="stat-label">Server</div>
        </div>
        <div class="card stat-box" style="margin:0;">
            <i class="fas fa-memory" style="font-size:1.5em; color:var(--warning); margin-bottom:5px;"></i>
            <span class="stat-value" data-count="<?= round($totalRam/1024, 1) ?>" data-suffix=" GB">0</span>
            <div class="stat-label">RAM</div>
        </div>
    </div>

    <!-- MODERN TABS -->
    <div class="tabs">
        <button class="tab-btn active" onclick="showTab('api', event)"><i class="fas fa-cog"></i> API</button>
        <button class="tab-btn" onclick="showTab('users', event)"><i class="fas fa-users"></i> Users</button>
        <button class="tab-btn" onclick="showTab('servers', event)"><i class="fas fa-server"></i> Servers</button>
        <button class="tab-btn" onclick="showTab('bc', event)"><i class="fas fa-bullhorn"></i> Broadcast</button>
    </div>

    <!-- TAB API -->
    <div id="tab-api" class="tab-content active">
        <div class="card">
            <h2 style="margin-bottom:15px;"><i class="fas fa-cog"></i> Setting API Pterodactyl</h2>
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
                        <form method="POST" style="margin:0;" onsubmit="return confirm('Hapus user?')"><input type="hidden" name="uid" value="<?= $u['id'] ?>"><button name="delete_user" class="btn btn-sm btn-danger"><i class="fas fa-trash"></i></button></form>
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
                <form method="POST" onsubmit="return confirm('Hapus server?')">
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
                <div class="form-group"><textarea name="message" rows="4" placeholder="Tulis pengumuman..." required></textarea></div>
                <button class="btn btn-primary btn-block"><i class="fas fa-paper-plane"></i> Kirim ke Semua User</button>
            </form>
        </div>
    </div>
</div>

<script>
function showTab(name, event) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    event.target.closest('.tab-btn').classList.add('active');
}

// STATS ANIMATION
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
echo -e "${GREEN}  ✅ Admin Panel v14 OK${NC}"

# ============ 3. UPDATE DASHBOARD (RAM OPTIONS) ============
echo -e "${CYAN}[3/5] Update Dashboard...${NC}"

if [ -f "$WEB_ROOT/dashboard.php" ]; then
    # Pastikan ada opsi RAM lengkap
    sed -i 's|<option value="0">Unlimited (∞)</option>|<option value="0">Unlimited (RAM Tanpa Batas)</option>|g' "$WEB_ROOT/dashboard.php" 2>/dev/null
fi

echo -e "${GREEN}  ✅ Dashboard OK${NC}"

# ============ 4. FIX PERMISSION ============
echo -e "${CYAN}[4/5] Fix Permission...${NC}"
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"
systemctl restart php8.3-fpm
echo -e "${GREEN}  ✅ Permission OK${NC}"

# ============ 5. SELESAI ============
echo -e "${CYAN}[5/5] Done!${NC}"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ RENDZZ ULTIMATE v14.0 SIAP!            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📌 Fitur Baru v14.0:${NC}"
echo -e "  📊 Live Stats Animation (Angka naik dari 0)"
echo -e "  🎯 Modern Tabs (Pill Style)"
echo -e "  🗑️  Admin: Delete User & Server"
echo -e "  🔑 Admin: Change Password User"
echo -e "  ♾️  RAM Unlimited di dashboard"
echo -e "  ☰ Hamburger Menu Navigasi"
echo -e "  🌓 Dark/Light Theme Toggle"
echo -e "  🎨 Semua icon FontAwesome"
echo ""
echo -e "${GREEN}🚀 Refresh browser (CTRL + SHIFT + R)!${NC}"
