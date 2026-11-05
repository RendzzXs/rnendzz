#!/bin/bash
# ============================================
#   🚀 RENDZZ v15.0 — LANDING PAGE PRO MAX
#   Hero • Stats • FAQ • Testimoni • CTA
# ============================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}❌ Harus root!${NC}"; exit 1; }

clear
echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  🚀 RENDZZ v15.0 — LANDING PAGE UPDATE    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
echo ""

read -p "👉 Subdomain Web (contoh: panel.domain.com): " DOMAIN
WEB_ROOT="/var/www/$DOMAIN"

if [ ! -d "$WEB_ROOT" ]; then
    echo -e "${RED}❌ Folder web tidak ditemukan!${NC}"
    exit 1
fi

# ============ UPDATE INDEX.PHP (LANDING PAGE) ============
echo -e "${CYAN}[1/2] Inject Landing Page Baru...${NC}"

cat > "$WEB_ROOT/index.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
$pageTitle = 'Home';

// Ambil Statistik Real
try {
    $totalUsers = $pdo->query("SELECT COUNT(*) FROM users WHERE role='user'")->fetchColumn();
    $totalServers = $pdo->query("SELECT COUNT(*) FROM servers")->fetchColumn();
    $ramTotal = $pdo->query("SELECT SUM(ram) FROM servers")->fetchColumn() ?: 0;
    $ramTotalGB = round($ramTotal / 1024, 1);
} catch (Exception $e) {
    $totalUsers = 0; $totalServers = 0; $ramTotalGB = 0;
}

include __DIR__ . '/includes/header.php';
?>

<style>
/* ==========================================
   LANDING PAGE PRO MAX
   ========================================== */

/* HERO SECTION */
.hero-section {
    text-align: center;
    padding: 80px 20px 60px;
    position: relative;
    overflow: hidden;
}

.hero-badge {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 8px 20px;
    background: rgba(99, 102, 241, 0.15);
    color: var(--primary);
    border-radius: 30px;
    font-size: 0.85em;
    font-weight: 700;
    margin-bottom: 25px;
    border: 1px solid rgba(99, 102, 241, 0.3);
    animation: pulse 2s infinite;
}

@keyframes pulse {
    0%, 100% { box-shadow: 0 0 0 0 rgba(99, 102, 241, 0.4); }
    50% { box-shadow: 0 0 0 10px rgba(99, 102, 241, 0); }
}

.hero-title {
    font-size: 3em;
    font-weight: 800;
    line-height: 1.15;
    margin-bottom: 20px;
    letter-spacing: -1.5px;
}

.hero-title .gradient-text {
    background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #ec4899 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    display: block;
}

.hero-subtitle {
    font-size: 1.15em;
    color: var(--text-muted);
    max-width: 600px;
    margin: 0 auto 35px;
    line-height: 1.6;
}

.hero-buttons {
    display: flex;
    gap: 12px;
    justify-content: center;
    flex-wrap: wrap;
    margin-bottom: 60px;
}

.btn-large {
    padding: 16px 32px;
    font-size: 1em;
    border-radius: 14px;
}

/* STATS SECTION */
.stats-section {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
    max-width: 800px;
    margin: 0 auto 80px;
    padding: 0 20px;
}

.stat-card {
    background: var(--card);
    backdrop-filter: blur(20px);
    border: 1px solid var(--glass-border);
    border-radius: 20px;
    padding: 30px 15px;
    text-align: center;
    transition: all 0.4s;
}

.stat-card:hover {
    transform: translateY(-8px);
    border-color: var(--primary);
    box-shadow: 0 20px 40px var(--primary-glow);
}

.stat-icon {
    width: 55px;
    height: 55px;
    border-radius: 16px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 15px;
    font-size: 1.4em;
    color: #fff;
}

.stat-number {
    font-size: 2em;
    font-weight: 800;
    background: linear-gradient(135deg, #6366f1, #ec4899);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    line-height: 1.2;
}

.stat-text {
    font-size: 0.8em;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 1px;
    font-weight: 700;
    margin-top: 4px;
}

/* SECTION */
.section {
    padding: 60px 20px;
    max-width: 1000px;
    margin: 0 auto;
}

.section-title {
    text-align: center;
    font-size: 2em;
    font-weight: 800;
    margin-bottom: 15px;
    letter-spacing: -1px;
}

.section-subtitle {
    text-align: center;
    color: var(--text-muted);
    font-size: 1.05em;
    margin-bottom: 50px;
    max-width: 600px;
    margin-left: auto;
    margin-right: auto;
}

/* FEATURE GRID */
.feature-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
    gap: 20px;
}

.feature-item {
    background: var(--card);
    backdrop-filter: blur(20px);
    border: 1px solid var(--glass-border);
    border-radius: 20px;
    padding: 30px 25px;
    transition: all 0.4s;
}

.feature-item:hover {
    transform: translateY(-8px);
    border-color: var(--primary);
    box-shadow: 0 20px 40px var(--primary-glow);
}

.feature-icon {
    width: 60px;
    height: 60px;
    border-radius: 18px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.5em;
    color: #fff;
    margin-bottom: 20px;
}

.feature-item h3 {
    font-size: 1.15em;
    margin-bottom: 10px;
}

.feature-item p {
    font-size: 0.9em;
    color: var(--text-muted);
    line-height: 1.6;
}

/* HOW IT WORKS */
.steps-container {
    display: flex;
    flex-direction: column;
    gap: 20px;
    max-width: 700px;
    margin: 0 auto;
}

.step {
    display: flex;
    align-items: center;
    gap: 20px;
    background: var(--card);
    backdrop-filter: blur(20px);
    border: 1px solid var(--glass-border);
    border-radius: 20px;
    padding: 25px;
    transition: all 0.3s;
}

.step:hover {
    transform: translateX(8px);
    border-color: var(--primary);
}

.step-number {
    width: 60px;
    height: 60px;
    border-radius: 50%;
    background: var(--gradient);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.5em;
    font-weight: 800;
    color: #fff;
    flex-shrink: 0;
    box-shadow: 0 8px 20px var(--primary-glow);
}

.step-content h3 {
    font-size: 1.1em;
    margin-bottom: 5px;
}

.step-content p {
    font-size: 0.9em;
    color: var(--text-muted);
}

/* TESTIMONI */
.testimonial-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 20px;
}

.testimonial {
    background: var(--card);
    backdrop-filter: blur(20px);
    border: 1px solid var(--glass-border);
    border-radius: 20px;
    padding: 25px;
    transition: all 0.3s;
}

.testimonial:hover {
    transform: translateY(-5px);
    border-color: var(--primary);
}

.testimonial-stars {
    color: #f59e0b;
    font-size: 1em;
    margin-bottom: 12px;
}

.testimonial-text {
    font-size: 0.95em;
    color: var(--text);
    line-height: 1.6;
    margin-bottom: 15px;
    font-style: italic;
}

.testimonial-author {
    display: flex;
    align-items: center;
    gap: 12px;
}

.testimonial-avatar {
    width: 45px;
    height: 45px;
    border-radius: 50%;
    background: var(--gradient);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
    font-weight: 800;
    font-size: 1.1em;
}

.testimonial-info h4 {
    font-size: 0.95em;
    margin-bottom: 2px;
}

.testimonial-info p {
    font-size: 0.8em;
    color: var(--text-muted);
}

/* FAQ */
.faq-container {
    max-width: 700px;
    margin: 0 auto;
}

.faq-item {
    background: var(--card);
    backdrop-filter: blur(20px);
    border: 1px solid var(--glass-border);
    border-radius: 16px;
    margin-bottom: 12px;
    overflow: hidden;
    transition: all 0.3s;
}

.faq-item:hover {
    border-color: var(--primary);
}

.faq-question {
    padding: 20px 25px;
    cursor: pointer;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-weight: 700;
    font-size: 1em;
    user-select: none;
}

.faq-question i {
    color: var(--primary);
    transition: transform 0.3s;
    font-size: 1.1em;
}

.faq-item.open .faq-question i {
    transform: rotate(45deg);
}

.faq-answer {
    max-height: 0;
    overflow: hidden;
    transition: max-height 0.4s ease, padding 0.4s ease;
    padding: 0 25px;
    color: var(--text-muted);
    font-size: 0.95em;
    line-height: 1.6;
}

.faq-item.open .faq-answer {
    max-height: 300px;
    padding: 0 25px 20px;
}

/* CTA FINAL */
.cta-final {
    text-align: center;
    padding: 80px 20px;
    background: linear-gradient(135deg, rgba(99, 102, 241, 0.2), rgba(236, 72, 153, 0.1));
    border-radius: 30px;
    border: 1px solid rgba(99, 102, 241, 0.3);
    max-width: 800px;
    margin: 40px auto;
}

.cta-final h2 {
    font-size: 2.2em;
    margin-bottom: 15px;
    letter-spacing: -1px;
}

.cta-final p {
    font-size: 1.05em;
    color: var(--text-muted);
    margin-bottom: 30px;
}

/* ANIMASI STATS */
@keyframes countUp {
    from { opacity: 0; transform: translateY(20px); }
    to { opacity: 1; transform: translateY(0); }
}

.stat-card {
    animation: countUp 0.6s ease-out;
}

/* RESPONSIVE */
@media (max-width: 768px) {
    .hero-title { font-size: 2em; }
    .hero-subtitle { font-size: 1em; }
    .stats-section { grid-template-columns: 1fr; }
    .section-title { font-size: 1.5em; }
    .cta-final h2 { font-size: 1.5em; }
    .step { flex-direction: column; text-align: center; }
    .step:hover { transform: translateY(-5px); }
}
</style>

<!-- ================= HERO SECTION ================= -->
<section class="hero-section">
    <div class="hero-badge"><i class="fas fa-fire"></i> Platform Terpercaya #1 di Indonesia</div>
    <h1 class="hero-title">
        Buat Server Impianmu
        <span class="gradient-text">Dalam Hitungan Detik</span>
    </h1>
    <p class="hero-subtitle">Deploy server Minecraft, Node.js, Bot WhatsApp, dan aplikasi lainnya dengan mudah. Pilih RAM, klik deploy, dan server langsung aktif 24/7!</p>

    <div class="hero-buttons">
        <a href="/register.php" class="btn btn-primary btn-large"><i class="fas fa-rocket"></i> Daftar Gratis</a>
        <a href="/login.php" class="btn btn-large" style="background:var(--card); color:var(--text); border:1px solid var(--glass-border)"><i class="fas fa-sign-in-alt"></i> Login</a>
    </div>
</section>

<!-- ================= STATS SECTION ================= -->
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

<!-- ================= FITUR UNGGULAN ================= -->
<section class="section">
    <h2 class="section-title">Kenapa Pilih <span style="background:var(--gradient); -webkit-background-clip:text; -webkit-text-fill-color:transparent;">RendzzPanel?</span></h2>
    <p class="section-subtitle">Kami memberikan pengalaman hosting terbaik dengan teknologi modern</p>

    <div class="feature-grid">
        <div class="feature-item">
            <div class="feature-icon" style="background:linear-gradient(135deg,#6366f1,#8b5cf6)"><i class="fas fa-bolt"></i></div>
            <h3>Instant Deploy</h3>
            <p>Server langsung jadi dalam 10 detik setelah kamu klik tombol Deploy. Gak pakai lama.</p>
        </div>
        <div class="feature-item">
            <div class="feature-icon" style="background:linear-gradient(135deg,#10b981,#059669)"><i class="fas fa-shield-halved"></i></div>
            <h3>Aman & Terpercaya</h3>
            <p>Data kamu dienkripsi dengan teknologi canggih. Server di-hosting di datacenter profesional.</p>
        </div>
        <div class="feature-item">
            <div class="feature-icon" style="background:linear-gradient(135deg,#f59e0b,#d97706)"><i class="fas fa-memory"></i></div>
            <h3>RAM Unlimited</h3>
            <p>Pilih paket dari 1GB sampai Unlimited. Bisa request custom sesuai kebutuhan kamu.</p>
        </div>
        <div class="feature-item">
            <div class="feature-icon" style="background:linear-gradient(135deg,#ec4899,#be185d)"><i class="fas fa-headset"></i></div>
            <h3>Support 24/7</h3>
            <p>Admin aktif dan siap bantu via Global Chat kalau kamu butuh bantuan kapan pun.</p>
        </div>
    </div>
</section>

<!-- ================= CARA KERJA ================= -->
<section class="section">
    <h2 class="section-title">Cara Kerja</h2>
    <p class="section-subtitle">Cuma butuh 3 langkah simpel untuk mulai</p>

    <div class="steps-container">
        <div class="step">
            <div class="step-number">1</div>
            <div class="step-content">
                <h3>Daftar Gratis</h3>
                <p>Bikin akun dalam 30 detik. Gak perlu kartu kredit atau verifikasi ribet.</p>
            </div>
        </div>
        <div class="step">
            <div class="step-number">2</div>
            <div class="step-content">
                <h3>Pilih RAM & Tipe Server</h3>
                <p>Tentukan paket RAM (1GB - Unlimited) dan nama server kamu.</p>
            </div>
        </div>
        <div class="step">
            <div class="step-number">3</div>
            <div class="step-content">
                <h3>Deploy & Selesai</h3>
                <p>Klik Deploy, tunggu 10 detik, server kamu langsung aktif!</p>
            </div>
        </div>
    </div>
</section>

<!-- ================= TESTIMONI ================= -->
<section class="section">
    <h2 class="section-title">Apa Kata Mereka?</h2>
    <p class="section-subtitle">Ribuan user sudah membuktikan kualitas layanan kami</p>

    <div class="testimonial-grid">
        <div class="testimonial">
            <div class="testimonial-stars"><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i></div>
            <p class="testimonial-text">"Gila sih ini, deploy server cuma butuh 10 detik doang. Gak pakai ribet. Recommended banget buat yang butuh server cepat!"</p>
            <div class="testimonial-author">
                <div class="testimonial-avatar">A</div>
                <div class="testimonial-info"><h4>Andi Pratama</h4><p>Content Creator</p></div>
            </div>
        </div>
        <div class="testimonial">
            <div class="testimonial-stars"><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i></div>
            <p class="testimonial-text">"Admin-nya fast respon banget. Pas server aku down, langsung dibantuin lewat Global Chat. Pelayanan top!"</p>
            <div class="testimonial-author">
                <div class="testimonial-avatar">S</div>
                <div class="testimonial-info"><h4>Siti Rahmawati</h4><p>Bot Developer</p></div>
            </div>
        </div>
        <div class="testimonial">
            <div class="testimonial-stars"><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i></div>
            <p class="testimonial-text">"RAM Unlimited nya worth it banget. Bisa jalanin Minecraft server + bot WhatsApp sekaligus tanpa lag!"</p>
            <div class="testimonial-author">
                <div class="testimonial-avatar">B</div>
                <div class="testimonial-info"><h4>Budi Santoso</h4><p>Minecraft Player</p></div>
            </div>
        </div>
    </div>
</section>

<!-- ================= FAQ ================= -->
<section class="section">
    <h2 class="section-title">Pertanyaan Umum</h2>
    <p class="section-subtitle">Belum nemu jawaban? Tanya admin di Global Chat</p>

    <div class="faq-container">
        <div class="faq-item">
            <div class="faq-question">Apakah ini gratis?<i class="fas fa-plus"></i></div>
            <div class="faq-answer">Ya! Daftar akun sepenuhnya gratis. Kamu bisa deploy server sesuai paket RAM yang tersedia tanpa biaya tersembunyi.</div>
        </div>
        <div class="faq-item">
            <div class="faq-question">Berapa lama server aktif?<i class="fas fa-plus"></i></div>
            <div class="faq-answer">Server aktif 24/7 selama masa aktif panel kamu. Bisa diperpanjang kapan saja tanpa downtime.</div>
        </div>
        <div class="faq-item">
            <div class="faq-question">Tipe server apa saja yang didukung?<i class="fas fa-plus"></i></div>
            <div class="faq-answer">Minecraft (Java & Bedrock), Node.js, Python, Bot WhatsApp, Telegram Bot, Web Hosting, dan masih banyak lagi.</div>
        </div>
        <div class="faq-item">
            <div class="faq-question">Bagaimana cara upgrade RAM?<i class="fas fa-plus"></i></div>
            <div class="faq-answer">Kontak admin via Global Chat atau fitur Support. Tim kami akan bantu upgrade sesuai kebutuhan kamu.</div>
        </div>
        <div class="faq-item">
            <div class="faq-question">Apakah data saya aman?<i class="fas fa-plus"></i></div>
            <div class="faq-answer">100% aman. Server di-hosting di datacenter profesional dengan sistem backup berlapis dan enkripsi SSL.</div>
        </div>
    </div>
</section>

<!-- ================= CTA FINAL ================= -->
<div class="cta-final">
    <h2>Siap Mulai Deploy?</h2>
    <p>Gak perlu kartu kredit. Gratis. Server siap dalam hitungan detik.</p>
    <div style="display:flex; gap:12px; justify-content:center; flex-wrap:wrap;">
        <a href="/register.php" class="btn btn-primary btn-large"><i class="fas fa-rocket"></i> Daftar Sekarang</a>
        <a href="/login.php" class="btn btn-large" style="background:rgba(255,255,255,0.1); color:var(--text); border:1px solid var(--glass-border)"><i class="fas fa-sign-in-alt"></i> Login</a>
    </div>
</div>

<!-- ================= SCRIPTS ================= -->
<script>
// COUNTER ANIMATION
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

// FAQ ACCORDION
document.querySelectorAll('.faq-question').forEach(q => {
    q.addEventListener('click', () => {
        const parent = q.closest('.faq-item');
        // Tutup semua FAQ lain
        document.querySelectorAll('.faq-item').forEach(item => {
            if (item !== parent) item.classList.remove('open');
        });
        parent.classList.toggle('open');
    });
});
</script>

<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

echo -e "${GREEN}  ✅ Landing Page Baru OK${NC}"

# ============ UPDATE CSS (TAMBAH STYLE) ============
echo -e "${CYAN}[2/2] Update CSS Tambahan...${NC}"

# Cek dulu, kalau belum ada section-style, tambahin
if ! grep -q "LANDING PAGE PRO MAX" "$WEB_ROOT/assets/css/style.css"; then
    cat >> "$WEB_ROOT/assets/css/style.css" << 'CSSEOF'

/* LANDING PAGE ADDITIONAL */
.hero-buttons .btn {
    min-width: 180px;
}

@media (max-width: 600px) {
    .hero-buttons .btn {
        width: 100%;
    }
    .stats-section {
        grid-template-columns: 1fr;
        gap: 12px;
    }
}
CSSEOF
fi

# Fix permission
chown -R www-data:www-data "$WEB_ROOT"
systemctl restart php8.3-fpm

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ LANDING PAGE v15.0 BERHASIL!           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📌 Fitur Landing Page Baru:${NC}"
echo -e "  🎯 Hero Section (Judul + Tombol CTA)"
echo -e "  📊 Live Stats (User, Server, RAM)"
echo -e "  ✨ Feature Grid (4 Fitur Unggulan)"
echo -e "  🚀 How It Works (3 Langkah Simpel)"
echo -e "  💬 Testimoni User (Card + Bintang)"
echo -e "  ❓ FAQ Accordion (Klik buka-tutup)"
echo -e "  🎯 CTA Final (Card Gradient)"
echo ""
echo -e "${GREEN}🚀 Refresh browser (CTRL + SHIFT + R)!${NC}"
