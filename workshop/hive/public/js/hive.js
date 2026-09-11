// Workshop Hive Table Client Logic — 3-Column Layout with Latency under Dot and Metrics next to Stack
const CACHE_KEY_LEADERBOARD = "hive_cached_leaderboard";
const CACHE_KEY_HEALTH = "hive_cached_health";

let cachedLeaderboard = [];
let cachedHealth = {};

// Max Age filter from Query String (e.g. ?max_age=24h or ?max_age=2d or ?max_age=1mo)
function getCurrentMaxAge() {
  const params = new URLSearchParams(window.location.search);
  return params.get("max_age") || "all";
}

let activeMaxAge = getCurrentMaxAge();

function updateTimeFilterUI() {
  const buttons = document.querySelectorAll(".time-filter-btn");
  buttons.forEach(btn => {
    const filter = btn.getAttribute("data-filter");
    if (filter === activeMaxAge || (activeMaxAge === "all" && filter === "all")) {
      btn.className = "time-filter-btn px-2.5 py-0.5 rounded transition-all font-semibold cursor-pointer bg-amber-500/20 text-amber-300 border border-amber-500/40 shadow-sm";
    } else {
      btn.className = "time-filter-btn px-2.5 py-0.5 rounded transition-all font-semibold cursor-pointer text-slate-400 hover:text-slate-200 hover:bg-slate-800 border border-transparent";
    }
  });
}

function setTimeFilter(filterVal) {
  activeMaxAge = filterVal;
  const url = new URL(window.location);
  if (filterVal === "all" || !filterVal) {
    url.searchParams.delete("max_age");
  } else {
    url.searchParams.set("max_age", filterVal);
  }
  window.history.replaceState({}, "", url);
  updateTimeFilterUI();
  fetchLeaderboard();
}

window.addEventListener("popstate", () => {
  activeMaxAge = getCurrentMaxAge();
  updateTimeFilterUI();
  fetchLeaderboard();
});

try {
  const savedLd = localStorage.getItem(CACHE_KEY_LEADERBOARD);
  if (savedLd) cachedLeaderboard = JSON.parse(savedLd);

  const savedHl = localStorage.getItem(CACHE_KEY_HEALTH);
  if (savedHl) cachedHealth = JSON.parse(savedHl);
} catch (e) {
  console.warn("Could not load from localStorage:", e);
}

// Render immediato prima ancora di fare qualsiasi fetch
document.addEventListener("DOMContentLoaded", () => {
  updateTimeFilterUI();
  if (cachedLeaderboard.length > 0) {
    document.getElementById("stat-total-students").textContent = cachedLeaderboard.length;
    const healthyCount = Object.values(cachedHealth).filter(c => c.status === "up").length;
    document.getElementById("stat-healthy-apps").textContent = healthyCount;
    renderTable();
  }
});

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
    const query = (activeMaxAge && activeMaxAge !== "all") ? `?max_age=${encodeURIComponent(activeMaxAge)}` : "";
    const res = await fetch(`/api/leaderboard${query}`);
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
    const newChecks = data.checks || {};
    
    // Preserva la telemetria precedente per ogni studente se il nuovo check è down/temporaneamente vuoto
    Object.keys(newChecks).forEach(url => {
      const incoming = newChecks[url];
      const prev = cachedHealth[url];
      if (prev && prev.telemetry && Object.keys(prev.telemetry).length > 0) {
        if (!incoming.telemetry || Object.keys(incoming.telemetry).length === 0) {
          incoming.telemetry = prev.telemetry;
        }
      }
    });

    cachedHealth = newChecks;
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
    const filterMsg = (activeMaxAge && activeMaxAge !== "all")
      ? `No submissions found in the last <b>${escapeHtml(activeMaxAge)}</b>. <button onclick="setTimeFilter('all')" class="text-amber-400 hover:underline cursor-pointer font-bold ml-1">Show All</button>`
      : "No student submissions registered yet.";

    tbody.innerHTML = `
      <tr>
        <td colspan="3" class="py-12 text-center text-slate-500 italic font-mono text-xs">
          ${filterMsg}
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


    // 2. Colonna 2: HH:MM Nome a sx + Visual Step Segmented Progress Bar con hover
    const hhmm = formatHHMM(student.timestamp);
    const nickname = student.nickname || "Anonymous";
    const rawStep = t.step_number || student.step_number || 1;
    let stepNum = Math.max(1, Math.min(8, parseInt(rawStep, 10) || 1));

    const isQuestSubmitted = !!(t.quest_ghi_issue);
    const isProctorApproved = (t.proctor_status === 'lgtm_approved');
    const isReviewPending = isQuestSubmitted && !isProctorApproved;

    // Se approvato dal proctor, il gradino è ufficialmente 8/8
    if (isProctorApproved) {
      stepNum = 8;
    } else if (isReviewPending && stepNum > 7) {
      // Se è in attesa di review ma il container riportava step 8, visualizziamo 7/8 con badge pending
      stepNum = 7;
    }

    const stepText = t.step_description ? t.step_description.replace(/Step \d+:\s*/, "") : (student.step || `Step ${stepNum}`);

    // Barra visiva a 8 segmenti orizzontali: ad es. [▮][▮][▮][▮][▯][▯][▯][▯] 4/8
    let segmentsHtml = "";
    for (let i = 1; i <= 8; i++) {
      if (i <= stepNum) {
        // Segmento completato / attivo
        const color = (i === 8) ? 'bg-purple-400' : (i >= 5 ? 'bg-amber-400' : 'bg-emerald-400');
        segmentsHtml += `<span class="w-1.5 h-3 rounded-[1px] ${color} inline-block shadow-sm"></span>`;
      } else {
        // Segmento futuro / spento
        segmentsHtml += `<span class="w-1.5 h-3 rounded-[1px] bg-slate-800 border border-slate-700/50 inline-block opacity-40"></span>`;
      }
    }

    const questUrl = t.quest_ghi_url || (t.quest_ghi_issue ? `https://github.com/palladius/rails8-app-on-gcp/issues/${t.quest_ghi_issue}` : null);

    let trophyHtml = "";
    let glowingBorderClass = "border-slate-700/60 hover:border-amber-500/50";
    if (stepNum === 8 && isProctorApproved) {
      glowingBorderClass = "border-purple-500/80 shadow-[0_0_12px_rgba(168,85,247,0.35)] bg-purple-950/40 ring-1 ring-purple-500/50";
      const reviewerText = t.proctor_reviewer ? ` by @${escapeHtml(t.proctor_reviewer)}` : "";
      if (questUrl) {
        trophyHtml = `<a href="${escapeHtml(questUrl)}" target="_blank" rel="noopener noreferrer" class="hover:scale-125 transition-transform inline-block ml-0.5" title="🎓 Graduation Approved${reviewerText}! Click to view Issue #${escapeHtml(t.quest_ghi_issue)}"><span class="text-[12px] leading-none">🏆</span></a>`;
      } else {
        trophyHtml = `<span class="text-[12px] leading-none ml-0.5" title="🎓 Graduation Approved${reviewerText}!">🏆</span>`;
      }
    } else if (stepNum === 8) {
      trophyHtml = '<span class="text-[11px] leading-none ml-0.5">🏆</span>';
    }

    let pendingBadgeHtml = "";
    if (isReviewPending && questUrl) {
      pendingBadgeHtml = `
        <div class="mt-0.5">
          <a href="${escapeHtml(questUrl)}" target="_blank" rel="noopener noreferrer" class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-mono bg-yellow-500/15 text-yellow-300 border border-yellow-500/30 hover:bg-yellow-500/25 hover:border-yellow-500/50 transition-colors" title="Quest submitted on GitHub! Awaiting proctor LGTM comment to graduate">
            <span class="text-xs leading-none animate-pulse">⏳</span>
            <span class="font-bold text-[9.5px]">GHI #${escapeHtml(t.quest_ghi_issue)} review pending</span>
          </a>
        </div>
      `;
    }

    let nameTrophyHtml = "";
    if (stepNum === 8) {
      const reviewerText = t.proctor_reviewer ? ` by @${escapeHtml(t.proctor_reviewer)}` : "";
      if (questUrl) {
        nameTrophyHtml = `<a href="${escapeHtml(questUrl)}" target="_blank" rel="noopener noreferrer" class="hover:scale-125 transition-transform inline-block ml-1" title="🎓 Graduation Approved${reviewerText}! Click to view Issue #${escapeHtml(t.quest_ghi_issue)}"><span class="text-sm leading-none">🏆</span></a>`;
      } else {
        nameTrophyHtml = `<span class="text-sm leading-none ml-1" title="🎓 Graduation Approved${reviewerText}!">🏆</span>`;
      }
    }

    const stepBarHtml = `
      <div class="flex items-center gap-1.5 ml-auto">
        <div class="inline-flex items-center gap-1.5 px-2 py-1 rounded-lg bg-slate-900/90 border ${glowingBorderClass} transition-all cursor-help group shadow-sm" title="Step ${stepNum} di 8: ${escapeHtml(stepText)}">
          <span class="font-mono text-[11px] font-bold tracking-tight">
            <span class="${stepNum === 8 ? 'text-purple-300' : 'text-yellow-400'} drop-shadow-[0_0_4px_rgba(250,204,21,0.3)]">${stepNum}</span><span class="text-amber-700/80 text-[10px]">/8</span>
          </span>
          <div class="flex items-center gap-0.5">
            ${segmentsHtml}
          </div>
          ${trophyHtml}
        </div>
      </div>
    `;

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

    // Google Cloud Triad Detection (Cloud SQL, GCS, Vertex AI)
    let gcpTriadHtml = "";
    if (hasTelemetry) {
      const isCloudSql = (t.db_tier && (t.db_tier.toString().includes("cloud_sql") || t.db_tier.toString().includes("Cloud SQL"))) || (t.db_badge && t.db_badge.includes("Cloud SQL"));
      const isGcs = (t.storage_tier && (t.storage_tier.toString().includes("gcs") || t.storage_tier.toString().includes("Cloud Storage"))) || (t.storage_badge && t.storage_badge.includes("Cloud Storage"));
      const isVertex = (t.ai_badge && (t.ai_badge.includes("Vertex") || t.ai_badge.includes("ADC")));

      // 1. Cloud SQL badge (Active green if Cloud SQL, else grayscale/crossed with red X)
      const sqlBadge = isCloudSql ? `
        <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded border border-emerald-500/40 bg-emerald-500/10 text-emerald-300 text-[10px] font-mono" title="Google Cloud SQL (mTLS Auth Proxy): ACTIVE">
          <span class="text-xs leading-none">🐘</span>
          <span class="font-bold text-[9px] tracking-tight">SQL</span>
        </span>
      ` : `
        <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded border border-slate-700/60 bg-slate-800/40 text-slate-500 text-[10px] font-mono grayscale opacity-60 hover:opacity-100 transition-opacity" title="Google Cloud SQL: Not configured yet (using ephemeral local SQLite)">
          <span class="text-xs leading-none filter grayscale">🐘</span>
          <span class="line-through text-[9px]">SQL</span>
          <span class="text-[8px] text-rose-500 font-bold">✕</span>
        </span>
      `;

      // 2. GCS badge (Active teal if GCS, else grayscale/crossed with red X)
      const gcsBadge = isGcs ? `
        <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded border border-teal-500/40 bg-teal-500/10 text-teal-300 text-[10px] font-mono" title="Google Cloud Storage (iam: true): ACTIVE">
          <span class="text-xs leading-none">☁️</span>
          <span class="font-bold text-[9px] tracking-tight">GCS</span>
        </span>
      ` : `
        <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded border border-slate-700/60 bg-slate-800/40 text-slate-500 text-[10px] font-mono grayscale opacity-60 hover:opacity-100 transition-opacity" title="Google Cloud Storage: Not configured yet (using ephemeral local disk)">
          <span class="text-xs leading-none filter grayscale">☁️</span>
          <span class="line-through text-[9px]">GCS</span>
          <span class="text-[8px] text-rose-500 font-bold">✕</span>
        </span>
      `;

      // 3. Vertex AI badge (Active amber if Vertex AI, else grayscale/crossed with red X)
      const vertexBadge = isVertex ? `
        <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded border border-amber-500/40 bg-amber-500/10 text-amber-300 text-[10px] font-mono" title="Vertex AI (Nano Banana / Imagen 3): ACTIVE">
          <span class="text-xs leading-none">🍌</span>
          <span class="font-bold text-[9px] tracking-tight">AI</span>
        </span>
      ` : `
        <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded border border-slate-700/60 bg-slate-800/40 text-slate-500 text-[10px] font-mono grayscale opacity-60 hover:opacity-100 transition-opacity" title="Vertex AI: Inactive (using Google AI Studio or disabled)">
          <span class="text-xs leading-none filter grayscale">🍌</span>
          <span class="line-through text-[9px]">AI</span>
          <span class="text-[8px] text-rose-500 font-bold">✕</span>
        </span>
      `;

      gcpTriadHtml = `
        <div class="flex items-center gap-1.5 pl-2 border-l border-slate-700/60">
          ${sqlBadge}
          ${gcsBadge}
          ${vertexBadge}
        </div>
      `;
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
        ${gcpTriadHtml}
      </div>
    ` : `
      <span class="text-[11px] font-mono text-slate-500 italic">Awaiting stack...</span>
    `;

    // Metriche e Delta Revision di fianco allo stack nella riga 2
    let metricsHtml = "";
    const statusJsonUrl = student.url.replace(/\/+$/, '') + '/status.json';

    const jobsBadge = (t.pending_jobs !== undefined)
      ? `<span class="bg-slate-800/80 px-2 py-0.5 rounded border border-slate-700/60 text-slate-300" title="Pending background jobs (Solid Queue)">⏳ <b class="text-amber-300 font-semibold">${t.pending_jobs}</b></span>`
      : "";

    // Calcolo della delta revision pura (es. "00013-l44")
    let deltaRevBadge = "";
    if (t.k_revision) {
      const service = t.k_service || (student.url.includes('.run.app') ? student.url.split('.')[0].replace(/^https?:\/\//, '').split('-').slice(0, 3).join('-') : null);
      let deltaRev = "";
      if (service) {
        deltaRev = t.k_revision.replace(new RegExp(`^${service}-?`), '');
      } else {
        deltaRev = t.k_revision;
      }

      // Se la diff non esiste o è vuota, o coincide con l'intero service name, o non è una vera revisione -> o perfetto o niente!
      if (deltaRev && deltaRev !== service && deltaRev.length > 0 && deltaRev !== 'deployed') {
        const hoverTitle = service ? `Cloud Run Service: ${service}\nFull Revision: ${t.k_revision}` : `Cloud Run Revision: ${t.k_revision}`;
        deltaRevBadge = `
          <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-mono bg-emerald-500/15 text-emerald-300 border border-emerald-500/30 hover:bg-emerald-500/25 hover:border-emerald-500/50 transition-colors cursor-help" title="${escapeHtml(hoverTitle)}">
            <span class="text-xs leading-none">🏷️</span>
            <span class="font-bold text-[9.5px] tracking-tight text-emerald-200">${escapeHtml(deltaRev)}</span>
          </span>
        `;
      }
    }

    // Failed jobs alert (se > 0, mostra badge rosso allarme!)
    const failedJobsBadge = (t.failed_jobs && t.failed_jobs > 0)
      ? `<span class="bg-rose-500/20 px-2 py-0.5 rounded border border-rose-500/40 text-rose-300 font-bold blink-down" title="Warning: ${t.failed_jobs} failed jobs in Solid Queue!">💥 <b class="text-rose-200">${t.failed_jobs}</b></span>`
      : "";

    // Git commit hash badge (se presente da Rails /status.json)
    const gitCommitBadge = t.git_commit
      ? `<span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-mono bg-sky-500/15 text-sky-300 border border-sky-500/30 hover:bg-sky-500/25 transition-colors cursor-help" title="Git Commit Hash: ${escapeHtml(t.git_commit)}">
          <span class="text-[10px]">⌥</span>
          <span class="font-bold text-[9.5px] tracking-tight">${escapeHtml(t.git_commit)}</span>
        </span>`
      : "";

    if (t.posts_count !== undefined) {
      metricsHtml = `
        <div class="flex items-center gap-2 text-xs font-mono pl-3 border-l border-slate-700/60">
          <span class="bg-slate-800/80 px-2 py-0.5 rounded border border-slate-700/60 text-slate-300" title="Posts count">📝 <b class="text-amber-300 font-semibold">${t.posts_count}</b></span>
          <span class="bg-slate-800/80 px-2 py-0.5 rounded border border-slate-700/60 text-slate-300" title="Admin users count">👤 <b class="text-sky-300 font-semibold">${t.users_count || 0}</b></span>
          <span class="bg-slate-800/80 px-2 py-0.5 rounded border border-slate-700/60 text-slate-300" title="Blobs/Images count">🖼️ <b class="text-emerald-300 font-semibold">${t.blobs_count || 0}</b></span>
          ${jobsBadge}
          ${failedJobsBadge}
          <a href="${escapeHtml(statusJsonUrl)}" target="_blank" rel="noopener noreferrer" class="inline-flex items-center hover:scale-125 transition-transform" title="Inspect raw telemetry JSON (/status.json)">
            <img src="/json_icon.png" class="w-4 h-4 object-contain inline-block drop-shadow-sm" alt="JSON">
          </a>
          ${deltaRevBadge}
          ${gitCommitBadge}
        </div>
      `;
    } else {
      metricsHtml = `
        <div class="flex items-center gap-2 text-xs font-mono pl-3 border-l border-slate-700/60">
          ${jobsBadge}
          ${failedJobsBadge}
          <a href="${escapeHtml(statusJsonUrl)}" target="_blank" rel="noopener noreferrer" class="inline-flex items-center hover:scale-125 transition-transform" title="Inspect raw telemetry JSON (/status.json)">
            <img src="/json_icon.png" class="w-4 h-4 object-contain inline-block drop-shadow-sm" alt="JSON">
          </a>
          ${deltaRevBadge}
          ${gitCommitBadge}
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

      <!-- COLONNA 2: HH:MM Nome (in giallo) + eventuale coppa + sotto GHI review pending + a dx Step bar fissa -->
      <td class="py-2 px-3 whitespace-nowrap align-middle">
        <div class="flex items-center justify-between gap-4">
          <div class="flex flex-col">
            <div class="flex items-center gap-1.5">
              <span class="text-[11px] font-mono text-slate-400 font-medium">${escapeHtml(hhmm)}</span>
              <span class="font-bold text-yellow-300 text-sm drop-shadow-sm">${escapeHtml(nickname)}</span>
              ${nameTrophyHtml}
              ${t.admin_email ? `
                <a href="mailto:${escapeHtml(t.admin_email)}" class="inline-flex items-center text-xs hover:scale-125 transition-transform ml-0.5" title="⚠️ Publicly exposed ADMIN_EMAIL: ${escapeHtml(t.admin_email)} (Ask Antigravity about Secret Manager hardening!)">
                  <img src="https://mailmeteor.com/logos/assets/PNG/Gmail_Logo_512px.png" class="w-3.5 h-3.5 inline-block opacity-90 hover:opacity-100" alt="Gmail">
                </a>
              ` : ''}
            </div>
            ${pendingBadgeHtml}
          </div>

          ${stepBarHtml}
        </div>
      </td>

      <!-- COLONNA 3: Riga 1 URL pulito con icona Cloud Run a sinistra; Riga 2 Stack Ruby/Rails + Metriche + JSON + Delta Revision -->
      <td class="py-2 px-3 align-middle">
        <div class="flex flex-col gap-1">
          <!-- Riga 1: Icona Cloud Run a inizio URL + URL -->
          <div class="flex items-center gap-2">
            <a href="${escapeHtml(student.url)}" target="_blank" rel="noopener noreferrer" class="font-mono text-xs text-sky-400 hover:text-sky-300 hover:underline flex items-center gap-1.5 break-all" title="${escapeHtml(student.url)}">
              <img src="/cloud_run_icon.png" class="w-4 h-4 object-contain inline-block drop-shadow-sm flex-shrink-0" alt="Cloud Run" title="Google Cloud Run">
              <span class="font-medium">${escapeHtml(student.url)}</span>
            </a>
          </div>

          <!-- Riga 2: Stack Ruby/Rails, Metriche, JSON icon e Delta Revision affiancati -->
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
    6: "Cloud SQL Proxy",
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
  if (str === null || str === undefined) return "";
  return String(str).replace(/[&<>"']/g, function(m) {
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
