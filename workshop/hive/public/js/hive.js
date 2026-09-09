// Workshop Hive Table Client Logic — 3-Column Layout with Latency under Dot and Metrics next to Stack
const CACHE_KEY_LEADERBOARD = "hive_cached_leaderboard";
const CACHE_KEY_HEALTH = "hive_cached_health";

let cachedLeaderboard = [];
let cachedHealth = {};

try {
  const savedLd = localStorage.getItem(CACHE_KEY_LEADERBOARD);
  if (savedLd) cachedLeaderboard = JSON.parse(savedLd);

  const savedHl = localStorage.getItem(CACHE_KEY_HEALTH);
  if (savedHl) cachedHealth = JSON.parse(savedHl);
} catch (e) {
  console.warn("Could not load from localStorage:", e);
}

// Render immediato prima ancora di fare qualsiasi fetch
if (cachedLeaderboard.length > 0) {
  document.addEventListener("DOMContentLoaded", () => {
    document.getElementById("stat-total-students").textContent = cachedLeaderboard.length;
    const healthyCount = Object.values(cachedHealth).filter(c => c.status === "up").length;
    document.getElementById("stat-healthy-apps").textContent = healthyCount;
    renderTable();
  });
}

let previousStudentsCount = cachedLeaderboard.length;
let audioContext = null;

function playArrivalChime() {
  try {
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) return;
    if (!audioContext) {
      audioContext = new AudioCtx();
    }
    if (audioContext.state === "suspended") {
      audioContext.resume();
    }

    const now = audioContext.currentTime;

    // Due note melodiche cristalline (Marimba / Celesta chime: Sol5 -> Do6, 784Hz -> 1046Hz)
    [ { freq: 783.99, time: 0 }, { freq: 1046.50, time: 0.12 } ].forEach(note => {
      const osc = audioContext.createOscillator();
      const gain = audioContext.createGain();

      osc.type = "sine";
      osc.frequency.setValueAtTime(note.freq, now + note.time);

      gain.gain.setValueAtTime(0, now + note.time);
      gain.gain.linearRampToValueAtTime(0.25, now + note.time + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, now + note.time + 0.45);

      osc.connect(gain);
      gain.connect(audioContext.destination);

      osc.start(now + note.time);
      osc.stop(now + note.time + 0.5);
    });
  } catch (e) {
    console.warn("Audio chime prevented by browser autoplay policy:", e);
  }
}

// Unlock audio context on any user click anywhere on the page
window.addEventListener("click", () => {
  if (audioContext && audioContext.state === "suspended") {
    audioContext.resume();
  }
}, { once: true });

async function fetchLeaderboard() {
  try {
    const res = await fetch("/api/leaderboard");
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    const newEntries = data.entries || [];

    // Suona il chime quando una nuova persona entra!
    if (previousStudentsCount > 0 && newEntries.length > previousStudentsCount) {
      playArrivalChime();
    }
    previousStudentsCount = newEntries.length;

    cachedLeaderboard = newEntries;
    try {
      localStorage.setItem(CACHE_KEY_LEADERBOARD, JSON.stringify(cachedLeaderboard));
    } catch {}
    document.getElementById("stat-total-students").textContent = cachedLeaderboard.length;
    renderTable();
  } catch (err) {
    console.error("Error fetching leaderboard:", err);
  }
}

async function fetchHealth() {
  try {
    const res = await fetch("/api/healthchecks");
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    cachedHealth = data.checks || {};
    try {
      localStorage.setItem(CACHE_KEY_HEALTH, JSON.stringify(cachedHealth));
    } catch {}

    const healthyCount = Object.values(cachedHealth).filter(c => c.status === "up").length;
    document.getElementById("stat-healthy-apps").textContent = healthyCount;
    document.getElementById("sync-timer").textContent = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false });

    renderTable();
  } catch (err) {
    console.error("Error fetching health checks:", err);
  }
}

function formatHHMM(isoOrStr) {
  if (!isoOrStr) return "--:--";
  try {
    const d = new Date(isoOrStr);
    if (!isNaN(d.getTime())) {
      return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false });
    }
  } catch {}

  const match = isoOrStr.match(/(\d{1,2}:\d{2})/);
  if (match) return match[1];

  return "--:--";
}

function renderTable() {
  const tbody = document.getElementById("leaderboard-tbody");
  if (!tbody) return;

  if (cachedLeaderboard.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="3" class="py-12 text-center text-slate-500 italic font-mono text-xs">
          No student submissions registered yet.
        </td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = "";

  cachedLeaderboard.forEach(student => {
    const check = cachedHealth[student.url] || { status: "unknown", latency_ms: null, http_code: null, telemetry: {} };
    const isUp = check.status === "up";
    const isDown = check.status === "down";
    const t = check.telemetry || {};

    // 1. Colonna 1: Spia rossa/verde + Sotto la latenza in ms (budget 2 righe, ultra compatta)
    let dotHtml = `<span class="w-3.5 h-3.5 rounded-full bg-slate-700 inline-block"></span>`;
    let latencyBadge = `<span class="font-mono text-[9px] text-slate-500 tracking-tight leading-none">-</span>`;

    const upUrl = student.url.replace(/\/+$/, '') + '/up';

    if (isUp) {
      dotHtml = `<a href="${escapeHtml(upUrl)}" target="_blank" rel="noopener noreferrer" class="hover:scale-125 transition-transform inline-block" title="200 OK — click to open /up"><span class="w-3.5 h-3.5 rounded-full bg-emerald-400 blink-up inline-block ring-2 ring-emerald-500/30"></span></a>`;
      latencyBadge = `<span class="font-mono text-[9px] text-emerald-400/90 font-normal tracking-tight leading-none">${check.latency_ms}ms</span>`;
    } else if (isDown) {
      dotHtml = `<a href="${escapeHtml(upUrl)}" target="_blank" rel="noopener noreferrer" class="hover:scale-125 transition-transform inline-block" title="DOWN — click to test /up"><span class="w-3.5 h-3.5 rounded-full bg-rose-500 blink-down inline-block ring-2 ring-rose-500/30"></span></a>`;
      latencyBadge = `<span class="font-mono text-[9px] text-rose-400/90 font-normal tracking-tight leading-none">${check.http_code ? 'H' + check.http_code : 'FAIL'}</span>`;
    }


    // 2. Colonna 2: HH:MM Nome a sx + Step badge con hover
    const hhmm = formatHHMM(student.timestamp);
    const nickname = student.nickname || "Anonymous";
    const stepNum = t.step_number || student.step_number || 1;
    const stepText = t.step_description ? t.step_description.replace(/Step \d+:\s*/, "") : (student.step || `Step ${stepNum}`);

    // 3. Colonna 3 (Riga 1): URL che occupa molto spazio
    //    Colonna 3 (Riga 2): Loghi Ruby/Rails + Metriche (Posts / Users / Images) di fianco!
    const rubyVersion = t.ruby_version || "3.3.8";
    const railsVersion = t.rails_version || "8.1.3";
    const railsEnv = (t.rails_env || "").trim();
    const hasTelemetry = !!t.ruby_version;

    // Colore per l'ambiente Rails: 'prod'/'production' verde, 'dev'/'development' giallo, 'test' rosso, altri grigio
    let envBadge = "";
    if (railsEnv) {
      const lower = railsEnv.toLowerCase();
      let colorClasses = "text-slate-400 bg-slate-800 border-slate-700"; // fallback verbatim
      let shortEnv = railsEnv;

      if (lower.startsWith("prod")) {
        colorClasses = "text-emerald-400 bg-emerald-500/15 border-emerald-500/30";
        shortEnv = "prod";
      } else if (lower.startsWith("dev")) {
        colorClasses = "text-yellow-400 bg-yellow-500/15 border-yellow-500/30";
        shortEnv = "dev";
      } else if (lower.startsWith("test")) {
        colorClasses = "text-rose-400 bg-rose-500/15 border-rose-500/30";
        shortEnv = "test";
      }

      envBadge = `<span class="px-1.5 py-0.2 rounded border text-[10px] font-bold ${colorClasses}" title="Rails.env: ${escapeHtml(railsEnv)}">${escapeHtml(shortEnv)}</span>`;
    }

    const stackHtml = hasTelemetry ? `
      <div class="flex items-center gap-2 text-xs font-mono">
        <span class="inline-flex items-center gap-1 text-rose-300 font-medium">
          <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/ruby/ruby-original.svg" class="w-3.5 h-3.5 inline-block" alt="Ruby">
          <span>${rubyVersion}</span>
        </span>
        ${envBadge}
        <span class="inline-flex items-center gap-1 text-red-300 font-medium">
          <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/rails/rails-plain.svg" class="w-3.5 h-3.5 inline-block" alt="Rails">
          <span>${railsVersion}</span>
        </span>
      </div>
    ` : `
      <span class="text-[11px] font-mono text-slate-500 italic">Awaiting stack...</span>
    `;

    // Metriche di fianco allo stack nella riga 2
    let metricsHtml = "";
    const statusJsonUrl = student.url.replace(/\/+$/, '') + '/status.json';

    if (t.posts_count !== undefined) {
      metricsHtml = `
        <div class="flex items-center gap-2 text-xs font-mono pl-3 border-l border-slate-700/60">
          <span class="bg-slate-800/80 px-2 py-0.5 rounded border border-slate-700/60 text-slate-300" title="Posts count">📝 <b class="text-amber-300 font-semibold">${t.posts_count}</b></span>
          <span class="bg-slate-800/80 px-2 py-0.5 rounded border border-slate-700/60 text-slate-300" title="Admin users count">👤 <b class="text-sky-300 font-semibold">${t.users_count || 0}</b></span>
          <span class="bg-slate-800/80 px-2 py-0.5 rounded border border-slate-700/60 text-slate-300" title="Blobs/Images count">🖼️ <b class="text-emerald-300 font-semibold">${t.blobs_count || 0}</b></span>
          <a href="${escapeHtml(statusJsonUrl)}" target="_blank" rel="noopener noreferrer" class="inline-flex items-center hover:scale-125 transition-transform" title="Inspect raw telemetry JSON (/status.json)">
            <img src="/json_icon.png" class="w-4 h-4 object-contain inline-block drop-shadow-sm" alt="JSON">
          </a>
        </div>
      `;
    } else {
      metricsHtml = `
        <div class="flex items-center gap-2 text-xs font-mono pl-3 border-l border-slate-700/60">
          <a href="${escapeHtml(statusJsonUrl)}" target="_blank" rel="noopener noreferrer" class="inline-flex items-center hover:scale-125 transition-transform" title="Inspect raw telemetry JSON (/status.json)">
            <img src="/json_icon.png" class="w-4 h-4 object-contain inline-block drop-shadow-sm" alt="JSON">
          </a>
        </div>
      `;
    }

    const tr = document.createElement("tr");
    tr.className = "hover:bg-slate-800/30 transition-colors";

    tr.innerHTML = `
      <!-- COLONNA 1: Live Dot + Sotto la latenza -->
      <td class="py-2 px-2.5 text-center whitespace-nowrap align-middle">
        <div class="flex flex-col items-center justify-center gap-0.5">
          ${dotHtml}
          ${latencyBadge}
        </div>
      </td>

      <!-- COLONNA 2: HH:MM Nome a sx + eventuale Gmail icon + Step badge -->
      <td class="py-2 px-3 whitespace-nowrap align-middle">
        <div class="flex items-center gap-2.5">
          <div class="flex items-baseline gap-1.5">
            <span class="text-[11px] font-mono text-slate-400 font-medium">${escapeHtml(hhmm)}</span>
            <span class="font-bold text-amber-400 text-sm">${escapeHtml(nickname)}</span>
            ${t.admin_email ? `
              <a href="mailto:${escapeHtml(t.admin_email)}" class="inline-flex items-center text-xs hover:scale-125 transition-transform ml-0.5" title="⚠️ Publicly exposed ADMIN_EMAIL: ${escapeHtml(t.admin_email)} (Ask Antigravity about Secret Manager hardening!)">
                <img src="https://mailmeteor.com/logos/assets/PNG/Gmail_Logo_512px.png" class="w-3.5 h-3.5 inline-block opacity-90 hover:opacity-100" alt="Gmail">
              </a>
            ` : ''}
          </div>

          <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-mono font-bold bg-amber-500/10 text-amber-300 border border-amber-500/30 hover:bg-amber-500/20 hover:border-amber-500/60 transition-all cursor-help ml-auto" title="${escapeHtml(stepText)}">
            <span>Step ${stepNum}</span>
            <span class="text-[9px] text-amber-400/60">ℹ️</span>
          </span>
        </div>
      </td>

      <!-- COLONNA 3: Riga 1 URL; Riga 2 Stack Ruby/Rails + Metriche di fianco -->
      <td class="py-2 px-3 align-middle">
        <div class="flex flex-col gap-1">
          <!-- Riga 1: URL largo + eventuale Cloud Run badge con icona ufficiale e hover -->
          <div class="flex items-center gap-2 flex-wrap">
            <a href="${escapeHtml(student.url)}" target="_blank" rel="noopener noreferrer" class="font-mono text-xs text-sky-400 hover:text-sky-300 hover:underline flex items-center gap-1 break-all" title="${escapeHtml(student.url)}">
              <span class="opacity-70 text-xs">🔗</span>
              <span class="font-medium">${escapeHtml(student.url)}</span>
            </a>

            ${(() => {
              const fullRev = (t.k_revision || '').trim();
              const fullService = (t.k_service || '').trim();
              const fallbackService = student.url.includes('.run.app') ? student.url.split('.')[0].replace(/^https?:\/\//, '').split('-').slice(0, 3).join('-') : null;
              const service = fullService || fallbackService;

              if (!service && !fullRev) return '';

              // Estrai il delta di revisione (es. "test-rails8-workshop-rails-app-00013-l44" -> "00013-l44")
              let deltaRev = '';
              if (fullRev) {
                if (service && fullRev.startsWith(service)) {
                  deltaRev = fullRev.slice(service.length).replace(/^-/, '');
                } else {
                  const match = fullRev.match(/(\d{5}-[a-z0-9]+)$/i) || fullRev.match(/(\d{4,}-[a-z0-9]+)$/i);
                  deltaRev = match ? match[1] : fullRev;
                }
              }

              const displayLabel = deltaRev ? `rev ${deltaRev}` : (fullRev || 'cloud-run');
              const hoverTitle = `Cloud Run Service: ${service || 'unknown'}\nFull Revision: ${fullRev || service || 'N/A'}`;

              return `
                <span class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[10.5px] font-mono bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 hover:bg-emerald-500/30 hover:border-emerald-500/60 shadow-sm transition-all cursor-help" title="${escapeHtml(hoverTitle)}">
                  <img src="/cloud_run_icon.png" class="w-3.5 h-3.5 object-contain inline-block drop-shadow-sm" alt="Cloud Run">
                  <span class="font-bold text-[10px] tracking-tight text-emerald-200 bg-emerald-950/60 px-1 rounded border border-emerald-500/30">${escapeHtml(displayLabel)}</span>
                </span>
              `;
            })()}
          </div>

          <!-- Riga 2: Stack Ruby/Rails e Metriche affiancate -->
          <div class="flex flex-wrap items-center gap-2.5">
            ${stackHtml}
            ${metricsHtml}
          </div>
        </div>
      </td>
    `;

    tbody.appendChild(tr);
  });

  renderStagesDistribution();
}

function renderStagesDistribution() {
  const container = document.getElementById("stages-distribution");
  if (!container) return;

  // Counts per step (1 to 8)
  const stepCounts = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0 };
  const stepNames = {
    1: "Local Baseline",
    2: "Mailpit & Admin",
    3: "Stateless Shock",
    4: "GCS Persistence",
    5: "Secret Manager",
    6: "Gold Sidecars",
    7: "GenAI Cover",
    8: "Final Quest 🏆"
  };

  cachedLeaderboard.forEach(student => {
    const check = cachedHealth[student.url] || {};
    const t = check.telemetry || {};
    const stepNum = t.step_number || student.step_number || 3;
    const clampedStep = Math.max(1, Math.min(8, stepNum));
    stepCounts[clampedStep] = (stepCounts[clampedStep] || 0) + 1;
  });

  container.innerHTML = "";

  for (let s = 1; s <= 8; s++) {
    const count = stepCounts[s] || 0;
    const isZero = count === 0;
    const isUltimate = s === 8;

    let cardClasses = "";
    let numberBadgeClasses = "";
    let labelClasses = "";

    if (isZero) {
      // Stadi nulli (compresi 1 e 2) trasparenti ed eterei
      cardClasses = "border border-slate-800/40 bg-slate-900/20 opacity-35 hover:opacity-70 transition-opacity";
      numberBadgeClasses = "text-slate-600";
      labelClasses = "text-slate-600";
    } else if (isUltimate) {
      // Ultimo stadio con colore speciale celebrativo (Viola/Fucsia o Oro con glow)
      cardClasses = "border-2 border-purple-500/60 bg-gradient-to-b from-purple-950/40 to-slate-900/90 shadow-lg shadow-purple-500/20";
      numberBadgeClasses = "text-purple-300 font-extrabold text-lg";
      labelClasses = "text-purple-300 font-bold";
    } else {
      // Stadi intermedi attivi (Ambra/Sky/Smeraldo)
      cardClasses = "border border-amber-500/40 bg-slate-900/80 shadow-md shadow-amber-500/10";
      numberBadgeClasses = "text-amber-400 font-bold text-lg";
      labelClasses = "text-slate-300 font-medium";
    }

    const card = document.createElement("div");
    card.className = `rounded-xl p-2.5 flex flex-col items-center justify-between text-center transition-all ${cardClasses}`;
    card.innerHTML = `
      <div class="flex items-center justify-between w-full text-[10px] font-mono mb-1">
        <span class="${isZero ? 'text-slate-600' : 'text-slate-400 font-bold'}">Step ${s}</span>
        ${isUltimate ? '<span class="text-xs">🏆</span>' : (s === 3 ? '<span class="text-[10px]" title="First Cloud Run deploy">☁️</span>' : '')}
      </div>
      <div class="my-1">
        <span class="font-mono text-xl ${numberBadgeClasses}">${count}</span>
      </div>
      <div class="text-[10px] leading-tight truncate max-w-full ${labelClasses}" title="${stepNames[s]}">
        ${stepNames[s]}
      </div>
    `;

    container.appendChild(card);
  }
}

function escapeHtml(str) {
  if (!str) return "";
  return str.replace(/[&<>"']/g, function(m) {
    return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[m];
  });
}

// Initial fetch & instant render
fetchLeaderboard();
fetchHealth();

// Refresh health every 5 seconds
setInterval(fetchHealth, 5000);

// Refresh submissions every 10 seconds
setInterval(fetchLeaderboard, 10000);
