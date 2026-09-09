// Workshop Hive Table Client Logic — Instant Local Cache + 5s Background Pings
const CACHE_KEY_LEADERBOARD = "hive_cached_leaderboard";
const CACHE_KEY_HEALTH = "hive_cached_health";

// Inizializza istantaneamente con i dati salvati in localStorage (0ms rendering al reload!)
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

async function fetchLeaderboard() {
  try {
    const res = await fetch("/api/leaderboard");
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    cachedLeaderboard = data.entries || [];
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
    document.getElementById("sync-timer").textContent = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });

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
      return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
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
        <td colspan="6" class="py-12 text-center text-slate-500 italic font-mono text-xs">
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

    // 1. Indicator Dot a sinistra
    let dotHtml = `<span class="w-3.5 h-3.5 rounded-full bg-slate-700 inline-block"></span>`;
    if (isUp) {
      dotHtml = `<span class="w-3.5 h-3.5 rounded-full bg-emerald-400 blink-up inline-block ring-2 ring-emerald-500/30" title="200 OK"></span>`;
    } else if (isDown) {
      dotHtml = `<span class="w-3.5 h-3.5 rounded-full bg-rose-500 blink-down inline-block ring-2 ring-rose-500/30" title="DOWN"></span>`;
    }

    // 2. Colonna Sinistra: HH:MM Nome (2 righe di budget)
    const hhmm = formatHHMM(student.timestamp);
    const nickname = student.nickname || "Anonymous";

    // 3. Step
    const stepNum = t.step_number || student.step_number || 1;
    const stepText = t.step_description ? t.step_description.replace(/Step \d+:\s*/, "") : (student.step || `Step ${stepNum}`);

    // 4. Sotto l'URL: Immagine logo Ruby + versione e logo Rails + versione
    const rubyVersion = t.ruby_version || "3.3.8";
    const railsVersion = t.rails_version || "8.1.3";
    const hasTelemetry = !!t.ruby_version;

    const stackHtml = hasTelemetry ? `
      <div class="flex items-center gap-3 text-[11px] font-mono mt-1">
        <span class="inline-flex items-center gap-1 text-rose-300 font-medium">
          <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/ruby/ruby-original.svg" class="w-3.5 h-3.5 inline-block" alt="Ruby">
          <span>${rubyVersion}</span>
        </span>
        <span class="text-slate-600">/</span>
        <span class="inline-flex items-center gap-1 text-red-300 font-medium">
          <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/rails/rails-plain.svg" class="w-3.5 h-3.5 inline-block" alt="Rails">
          <span>${railsVersion}</span>
        </span>
      </div>
    ` : `
      <div class="text-[11px] font-mono text-slate-500 italic mt-1">
        Awaiting stack telemetry...
      </div>
    `;

    // 5. Metrics (Posts / Users / Images)
    let metricsHtml = `<span class="text-slate-600 text-xs italic font-mono">Awaiting /status</span>`;
    if (t.posts_count !== undefined) {
      metricsHtml = `
        <div class="flex items-center gap-2 text-xs font-mono">
          <span class="bg-slate-800/80 px-2 py-0.5 rounded border border-slate-700/60 text-slate-300" title="Posts count">📝 <b class="text-amber-300 font-semibold">${t.posts_count}</b></span>
          <span class="bg-slate-800/80 px-2 py-0.5 rounded border border-slate-700/60 text-slate-300" title="Admin users count">👤 <b class="text-sky-300 font-semibold">${t.users_count || 0}</b></span>
          <span class="bg-slate-800/80 px-2 py-0.5 rounded border border-slate-700/60 text-slate-300" title="Blobs/Images count">🖼️ <b class="text-emerald-300 font-semibold">${t.blobs_count || 0}</b></span>
        </div>
      `;
    }

    // 6. Latency
    const latencyBadge = isUp
      ? `<span class="font-mono text-xs font-medium text-emerald-400 bg-emerald-950/50 px-2.5 py-1 rounded border border-emerald-800/50 shadow-sm">${check.latency_ms} ms</span>`
      : isDown
      ? `<span class="font-mono text-xs font-medium text-rose-400 bg-rose-950/50 px-2.5 py-1 rounded border border-rose-800/50 shadow-sm">${check.http_code ? 'HTTP ' + check.http_code : 'FAIL'}</span>`
      : `<span class="font-mono text-xs text-slate-500">-</span>`;

    const tr = document.createElement("tr");
    tr.className = "hover:bg-slate-800/30 transition-colors";

    tr.innerHTML = `
      <!-- Live Indicator (Left) -->
      <td class="py-3.5 px-4 text-center whitespace-nowrap align-middle">
        <div class="flex items-center justify-center">
          ${dotHtml}
        </div>
      </td>

      <!-- HH:MM & Nome a sx (2 righe di budget) -->
      <td class="py-3.5 px-5 whitespace-nowrap align-middle">
        <div class="flex flex-col">
          <div class="font-bold text-slate-100 text-base flex items-center gap-1.5">
            <span class="text-amber-400">${escapeHtml(nickname)}</span>
          </div>
          <div class="text-xs font-mono text-slate-400 flex items-center gap-1 mt-0.5">
            <span class="text-slate-500">🕒</span>
            <span>${escapeHtml(hhmm)}</span>
          </div>
        </div>
      </td>

      <!-- Step (Hover to see full description) -->
      <td class="py-3.5 px-5 whitespace-nowrap align-middle">
        <span class="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-mono font-bold bg-amber-500/10 text-amber-300 border border-amber-500/30 hover:bg-amber-500/20 hover:border-amber-500/60 transition-all cursor-help" title="${escapeHtml(stepText)}">
          <span>Step ${stepNum}</span>
          <span class="text-[10px] text-amber-400/60">ℹ️</span>
        </span>
      </td>

      <!-- URL occupa molto spazio + Sotto logo Ruby & Rails con versioni (2 righe di budget) -->
      <td class="py-3.5 px-5 align-middle">
        <div class="flex flex-col">
          <a href="${escapeHtml(student.url)}" target="_blank" rel="noopener noreferrer" class="font-mono text-xs text-sky-400 hover:text-sky-300 hover:underline flex items-center gap-1.5 break-all max-w-xl" title="${escapeHtml(student.url)}">
            <span class="opacity-70 text-sm">🔗</span>
            <span class="font-medium">${escapeHtml(student.url)}</span>
          </a>
          ${stackHtml}
        </div>
      </td>

      <!-- Metrics -->
      <td class="py-3.5 px-5 whitespace-nowrap align-middle">
        ${metricsHtml}
      </td>

      <!-- Latency -->
      <td class="py-3.5 px-5 whitespace-nowrap text-right align-middle">
        ${latencyBadge}
      </td>
    `;

    tbody.appendChild(tr);
  });
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

// Refresh submissions every 15 seconds
setInterval(fetchLeaderboard, 15000);
