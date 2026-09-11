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
  updateDuplicateFilterUI();
  fetchLeaderboard();
});

function normalizeUrl(urlStr) {
  if (!urlStr) return "";
  let str = urlStr.trim();
  if (!/^https?:\/\//i.test(str)) {
    str = "https://" + str;
  }
  try {
    const u = new URL(str);
    const host = u.hostname.toLowerCase();
    const scheme = host.endsWith(".run.app") ? "https:" : u.protocol.toLowerCase();
    const port = (u.port && u.port !== "80" && u.port !== "443") ? `:${u.port}` : "";
    const path = u.pathname.replace(/\/+$/, "");
    return `${scheme}//${host}${port}${path}`;
  } catch (e) {
    return str.toLowerCase().replace(/\/+$/, "");
  }
}

function deduplicateEntries(entries) {
  if (!Array.isArray(entries)) return [];
  const seen = new Map();
  // Reverse iteration so the last entry seen is preserved (the latest submission)
  for (let i = entries.length - 1; i >= 0; i--) {
    const entry = entries[i];
    const key = normalizeUrl(entry.url);
    if (!seen.has(key)) {
      seen.set(key, entry);
    }
  }
  return Array.from(seen.values()).reverse();
}

function shouldShowDuplicates() {
  const params = new URLSearchParams(window.location.search);
  return params.get("show_duplicates") === "true" ||
         params.get("show_duplicates") === "1" ||
         params.get("show_duplicatees") === "true" ||
         params.has("show_duplicates_true") ||
         params.has("show_duplicatees_true") ||
         params.get("show_duplicates_true") === "true" ||
         params.get("show_duplicatees_true") === "true";
}

const STORAGE_KEY_COMPACT = "hive_compact_mode";

function isCompactMode() {
  const params = new URLSearchParams(window.location.search);
  const paramVal = params.get("compact") || params.get("density");
  if (paramVal === "true" || paramVal === "1" || paramVal === "compact" || params.has("compact_true")) {
    return true;
  }
  if (paramVal === "false" || paramVal === "0" || paramVal === "full" || paramVal === "expanded") {
    return false;
  }
  try {
    return localStorage.getItem(STORAGE_KEY_COMPACT) === "true";
  } catch {
    return false;
  }
}

function updateCompactViewUI() {
  const btn = document.getElementById("compact-view-btn");
  const label = document.getElementById("compact-view-label");
  const compact = isCompactMode();
  if (btn) {
    if (compact) {
      btn.className = "px-2.5 py-0.5 rounded transition-all font-semibold cursor-pointer bg-amber-500/20 text-amber-300 border border-amber-500/40 shadow-sm flex items-center gap-1";
      if (label) label.textContent = "View: Compact (50+)";
    } else {
      btn.className = "px-2.5 py-0.5 rounded transition-all font-semibold cursor-pointer text-slate-400 hover:text-slate-200 hover:bg-slate-800 border border-transparent flex items-center gap-1";
      if (label) label.textContent = "View: Full";
    }
  }

  const mainContainer = document.querySelector("main");
  if (mainContainer) {
    if (compact) {
      mainContainer.classList.add("hive-compact-active");
    } else {
      mainContainer.classList.remove("hive-compact-active");
    }
  }
}

function toggleCompactMode() {
  const url = new URL(window.location);
  const nextState = !isCompactMode();

  if (nextState) {
    url.searchParams.set("compact", "true");
    url.searchParams.delete("density");
    try { localStorage.setItem(STORAGE_KEY_COMPACT, "true"); } catch {}
  } else {
    url.searchParams.delete("compact");
    url.searchParams.delete("density");
    try { localStorage.setItem(STORAGE_KEY_COMPACT, "false"); } catch {}
  }

  window.history.replaceState({}, "", url);
  updateCompactViewUI();
  renderTable();
}

function updateDuplicateFilterUI() {
  const btn = document.getElementById("dupe-filter-btn");
  const label = document.getElementById("dupe-filter-label");
  if (!btn) return;
  const showDupes = shouldShowDuplicates();
  if (showDupes) {
    btn.className = "px-2.5 py-0.5 rounded transition-all font-semibold cursor-pointer bg-purple-500/20 text-purple-300 border border-purple-500/40 shadow-sm flex items-center gap-1";
    if (label) label.textContent = "Dupes: ON";
  } else {
    btn.className = "px-2.5 py-0.5 rounded transition-all font-semibold cursor-pointer text-slate-400 hover:text-slate-200 hover:bg-slate-800 border border-transparent flex items-center gap-1";
    if (label) label.textContent = "Dupes: Off";
  }
}

function toggleDuplicates() {
  const url = new URL(window.location);
  if (shouldShowDuplicates()) {
    url.searchParams.delete("show_duplicates");
    url.searchParams.delete("show_duplicatees");
    url.searchParams.delete("show_duplicates_true");
    url.searchParams.delete("show_duplicatees_true");
  } else {
    url.searchParams.set("show_duplicates", "true");
  }
  window.history.replaceState({}, "", url);
  updateDuplicateFilterUI();
  fetchLeaderboard();
}

try {
  const savedLd = localStorage.getItem(CACHE_KEY_LEADERBOARD);
  if (savedLd) {
    const parsed = JSON.parse(savedLd);
    cachedLeaderboard = shouldShowDuplicates() ? parsed : deduplicateEntries(parsed);
  }

  const savedHl = localStorage.getItem(CACHE_KEY_HEALTH);
  if (savedHl) cachedHealth = JSON.parse(savedHl);
} catch (e) {
  console.warn("Could not load from localStorage:", e);
}

// Render immediato prima ancora di fare qualsiasi fetch
document.addEventListener("DOMContentLoaded", () => {
  updateTimeFilterUI();
  updateDuplicateFilterUI();
  updateCompactViewUI();
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
    const queryParams = new URLSearchParams();
    if (activeMaxAge && activeMaxAge !== "all") queryParams.set("max_age", activeMaxAge);
    if (shouldShowDuplicates()) queryParams.set("show_duplicates", "true");
    const query = queryParams.toString() ? `?${queryParams.toString()}` : "";

    const res = await fetch(`/api/leaderboard${query}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    const newEntries = shouldShowDuplicates() ? (data.entries || []) : deduplicateEntries(data.entries || []);

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

  const match = String(isoOrStr).match(/(\d{1,2}:\d{2})/);
  if (match) return match[1];

  return "--:--";
}

function getVictoryTimestamp(student, t) {
  if (t && t.proctor_approved_at) return t.proctor_approved_at;
  if (t && t.checked_at) return t.checked_at;
  return student.timestamp;
}

function computeStep8Winners() {
  const winners = [];
  cachedLeaderboard.forEach(student => {
    const check = cachedHealth[student.url] || {};
    const t = check.telemetry || {};
    const isProctorApproved = (t.proctor_status === 'lgtm_approved');
    const rawStep = t.step_number || student.step_number || 1;
    const stepNum = isProctorApproved ? 8 : Math.max(1, Math.min(8, parseInt(rawStep, 10) || 1));

    if (stepNum === 8) {
      const wonAtStr = getVictoryTimestamp(student, t);
      const wonDate = new Date(wonAtStr);
      winners.push({
        url: student.url,
        nickname: student.nickname || "Anonymous",
        wonAt: wonAtStr,
        wonAtTime: !isNaN(wonDate.getTime()) ? wonDate.getTime() : 9999999999999,
        hhmm: formatHHMM(wonAtStr),
        proctor_reviewer: t.proctor_reviewer,
        quest_ghi_issue: t.quest_ghi_issue,
        quest_ghi_url: t.quest_ghi_url || (t.quest_ghi_issue ? `https://github.com/palladius/rails8-app-on-gcp/issues/${t.quest_ghi_issue}` : null)
      });
    }
  });

  // Sort ascending: first to reach Step 8 gets Rank 1!
  winners.sort((a, b) => a.wonAtTime - b.wonAtTime);

  return winners.map((w, idx) => {
    const rank = idx + 1;
    const medal = (rank === 1) ? '🥇' : ((rank === 2) ? '🥈' : ((rank === 3) ? '🥉' : '🏆'));
    const suffix = (rank === 1) ? 'st' : ((rank === 2) ? 'nd' : ((rank === 3) ? 'rd' : 'th'));
    return {
      ...w,
      rank,
      medal,
      suffix
    };
  });
}

function renderStep8Podium(winners) {
  const container = document.getElementById("step8-podium-container");
  if (!container) return;

  if (!winners || winners.length === 0) {
    container.classList.add("hidden");
    container.innerHTML = "";
    return;
  }

  container.classList.remove("hidden");

  let chipsHtml = "";
  winners.forEach(w => {
    let rankBadgeClass = "";
    let borderClass = "";
    let bgClass = "";
    let medalBg = "";

    if (w.rank === 1) {
      bgClass = "bg-gradient-to-r from-amber-500/20 via-yellow-500/15 to-amber-600/10";
      borderClass = "border-amber-400/70 shadow-[0_0_12px_rgba(251,191,36,0.3)]";
      rankBadgeClass = "text-amber-200 font-extrabold";
      medalBg = "bg-amber-950/80 text-amber-300 border-amber-500/40";
    } else if (w.rank === 2) {
      bgClass = "bg-slate-400/15";
      borderClass = "border-slate-400/60 shadow-[0_0_8px_rgba(148,163,184,0.25)]";
      rankBadgeClass = "text-slate-200 font-bold";
      medalBg = "bg-slate-900/80 text-slate-300 border-slate-500/40";
    } else if (w.rank === 3) {
      bgClass = "bg-amber-700/20";
      borderClass = "border-amber-600/60 shadow-[0_0_8px_rgba(217,119,6,0.25)]";
      rankBadgeClass = "text-amber-300 font-bold";
      medalBg = "bg-amber-950/80 text-amber-400 border-amber-700/40";
    } else {
      bgClass = "bg-purple-950/30";
      borderClass = "border-purple-500/40";
      rankBadgeClass = "text-purple-300 font-medium";
      medalBg = "bg-purple-900/40 text-purple-200 border-purple-500/30";
    }

    const reviewerText = w.proctor_reviewer ? ` (Approved by @${escapeHtml(w.proctor_reviewer)})` : "";
    const titleText = `${w.rank}${w.suffix} Place! Completed Step 8 at ${w.hhmm}${reviewerText}`;

    chipsHtml += `
      <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl ${bgClass} border ${borderClass} transition-all hover:scale-[1.03] shadow-sm" title="${escapeHtml(titleText)}">
        <span class="text-lg leading-none">${w.medal}</span>
        <div class="flex items-baseline gap-1.5 font-mono">
          <span class="text-xs ${rankBadgeClass}">${escapeHtml(w.nickname)}</span>
          <span class="text-[10px] px-1.5 py-0.2 rounded border ${medalBg} font-semibold">${escapeHtml(w.hhmm)}</span>
        </div>
        ${w.quest_ghi_issue ? `
          <a href="${escapeHtml(w.quest_ghi_url)}" target="_blank" rel="noopener noreferrer" class="text-[10px] font-mono text-amber-400/80 hover:text-amber-300 hover:underline" title="View Issue #${escapeHtml(w.quest_ghi_issue)}">#${escapeHtml(w.quest_ghi_issue)}</a>
        ` : ''}
      </div>
    `;
  });

  const compact = isCompactMode();
  if (compact) {
    container.innerHTML = `
      <div class="bg-gradient-to-r from-amber-500/10 via-purple-500/15 to-slate-900/90 border border-amber-500/30 rounded-xl px-3 py-1.5 flex items-center justify-between gap-3 shadow-md mb-1 text-xs">
        <div class="flex items-center gap-2 shrink-0">
          <span class="text-base leading-none">🏆</span>
          <span class="font-extrabold text-amber-300 text-[11px] uppercase tracking-wider">Step 8 Champions Podium</span>
        </div>
        <div class="flex items-center gap-2 overflow-x-auto min-w-0 py-0.5">
          ${chipsHtml}
        </div>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="bg-gradient-to-r from-amber-500/10 via-purple-500/15 to-slate-900/90 border border-amber-500/30 rounded-2xl p-3.5 flex flex-wrap items-center justify-between gap-4 shadow-xl mb-1">
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 rounded-xl bg-amber-500/15 border border-amber-500/40 flex items-center justify-center text-2xl shadow-inner">
          🏆
        </div>
        <div>
          <div class="text-xs font-black text-amber-300 uppercase tracking-wider flex items-center gap-1.5">
            <span>Step 8 Champions Podium</span>
            <span class="text-slate-600">•</span>
            <span class="text-[10px] font-mono text-purple-300 font-normal">First to Finish (Victory Chronology)</span>
          </div>
          <p class="text-[11px] text-slate-400 mt-0.5">
            Students who completed the final quest, ranked strictly by timestamp of victory!
          </p>
        </div>
      </div>

      <div class="flex items-center gap-2.5 flex-wrap">
        ${chipsHtml}
      </div>
    </div>
  `;
}

function renderTable() {
  const tbody = document.getElementById("leaderboard-tbody");
  if (!tbody) return;

  const compact = isCompactMode();

  const step8Winners = computeStep8Winners();
  renderStep8Podium(step8Winners);

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
        segmentsHtml += `<span class="w-1.5 h-3 rounded-[1px] ${color} inline-block shadow-sm shrink-0"></span>`;
      } else {
        // Segmento futuro / spento
        segmentsHtml += `<span class="w-1.5 h-3 rounded-[1px] bg-slate-800 border border-slate-700/50 inline-block opacity-40 shrink-0"></span>`;
      }
    }

    const questUrl = t.quest_ghi_url || (t.quest_ghi_issue ? `https://github.com/palladius/rails8-app-on-gcp/issues/${t.quest_ghi_issue}` : null);

    let trophyHtml = "";
    let glowingBorderClass = "border-slate-700/60 hover:border-amber-500/50";

    const winnerIndex = step8Winners.findIndex(w => w.url === student.url);
    const winner = (winnerIndex !== -1) ? step8Winners[winnerIndex] : null;

    if (winner) {
      glowingBorderClass = (winner.rank === 1)
        ? "border-amber-400/90 shadow-[0_0_12px_rgba(251,191,36,0.35)] bg-amber-950/40 ring-1 ring-amber-400/50"
        : "border-purple-500/80 shadow-[0_0_10px_rgba(168,85,247,0.35)] bg-purple-950/40 ring-1 ring-purple-500/50";

      const reviewerText = t.proctor_reviewer ? ` by @${escapeHtml(t.proctor_reviewer)}` : "";
      const rankTitle = `🎓 ${winner.rank}${winner.suffix} Place Champion! Completed Step 8 at ${winner.hhmm}${reviewerText}`;

      if (questUrl) {
        trophyHtml = `<a href="${escapeHtml(questUrl)}" target="_blank" rel="noopener noreferrer" class="hover:scale-125 transition-transform inline-flex items-center shrink-0" title="${escapeHtml(rankTitle)} — Click to view Issue #${escapeHtml(t.quest_ghi_issue)}"><span class="text-sm leading-none">${winner.medal}</span></a>`;
      } else {
        trophyHtml = `<span class="text-sm leading-none shrink-0" title="${escapeHtml(rankTitle)}">${winner.medal}</span>`;
      }
    } else if (stepNum === 8) {
      glowingBorderClass = "border-purple-500/60 bg-purple-950/30";
      trophyHtml = '<span class="text-sm leading-none shrink-0" title="Step 8 Complete!">🏆</span>';
    } else if (isReviewPending && questUrl) {
      trophyHtml = `<a href="${escapeHtml(questUrl)}" target="_blank" rel="noopener noreferrer" class="hover:scale-125 transition-transform inline-flex items-center shrink-0" title="⏳ Quest submitted on GitHub! Awaiting proctor LGTM comment to graduate (Issue #${escapeHtml(t.quest_ghi_issue)})"><span class="text-xs leading-none animate-pulse">⏳</span></a>`;
    }

    const stepBarHtml = `
      <div class="inline-flex items-center justify-between px-2 py-1 rounded-lg bg-slate-900/90 border ${glowingBorderClass} transition-all cursor-help group shadow-sm w-[98px] shrink-0" title="Step ${stepNum} di 8: ${escapeHtml(stepText)}">
        <span class="font-mono text-[11px] font-bold tracking-tight shrink-0">
          <span class="${stepNum === 8 ? 'text-purple-300' : 'text-amber-400'} drop-shadow-[0_0_4px_rgba(251,191,36,0.3)]">${stepNum}</span><span class="text-amber-700/80 text-[10px]">/8</span>
        </span>
        <div class="flex items-center gap-0.5 shrink-0">
          ${segmentsHtml}
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

    if (compact) {
      tr.className = "hover:bg-slate-800/40 transition-colors border-b border-slate-800/30 text-xs";
      const dotHtmlCompact = isUp
        ? `<a href="${escapeHtml(upUrl)}" target="_blank" rel="noopener noreferrer" class="hover:scale-125 transition-transform inline-block" title="200 OK — click to open /up"><span class="w-2.5 h-2.5 rounded-full bg-emerald-400 blink-up inline-block ring-1 ring-emerald-500/40"></span></a>`
        : (isDown
            ? `<a href="${escapeHtml(upUrl)}" target="_blank" rel="noopener noreferrer" class="hover:scale-125 transition-transform inline-block" title="DOWN — click to test /up"><span class="w-2.5 h-2.5 rounded-full bg-rose-500 blink-down inline-block ring-1 ring-rose-500/40"></span></a>`
            : `<span class="w-2.5 h-2.5 rounded-full bg-slate-700 inline-block"></span>`);

      const latencyBadgeCompact = isUp
        ? `<span class="font-mono text-[10px] text-emerald-400 font-normal leading-none">${check.latency_ms}ms</span>`
        : (isDown
            ? `<span class="font-mono text-[10px] text-rose-400 font-normal leading-none">${check.http_code ? 'H' + check.http_code : 'FAIL'}</span>`
            : `<span class="font-mono text-[10px] text-slate-500 leading-none">-</span>`);

      const trophyHtmlCompact = winner
        ? (questUrl
            ? `<a href="${escapeHtml(questUrl)}" target="_blank" rel="noopener noreferrer" class="hover:scale-125 transition-transform inline-flex items-center shrink-0" title="${escapeHtml(rankTitle)} — Click to view Issue #${escapeHtml(t.quest_ghi_issue)}"><span class="text-xs leading-none">${winner.medal}</span></a>`
            : `<span class="text-xs leading-none shrink-0" title="${escapeHtml(rankTitle)}">${winner.medal}</span>`)
        : (stepNum === 8
            ? '<span class="text-xs leading-none shrink-0" title="Step 8 Complete!">🏆</span>'
            : (isReviewPending && questUrl
                ? `<a href="${escapeHtml(questUrl)}" target="_blank" rel="noopener noreferrer" class="hover:scale-125 transition-transform inline-flex items-center shrink-0" title="⏳ Quest submitted on GitHub! Awaiting proctor review"><span class="text-[11px] leading-none animate-pulse">⏳</span></a>`
                : ''));

      tr.innerHTML = `
        <!-- COLONNA 1: Live Dot + Latency inline -->
        <td class="py-1 px-2 text-center whitespace-nowrap align-middle">
          <div class="flex items-center justify-center gap-1 font-mono">
            ${dotHtmlCompact}
            ${latencyBadgeCompact}
          </div>
        </td>

        <!-- COLONNA 2: HH:MM [Medaglia/Coppa] Nome + Step Bar fissa a destra -->
        <td class="py-1 px-2.5 align-middle w-[320px] overflow-hidden whitespace-nowrap">
          <div class="flex items-center justify-between gap-1.5 w-full overflow-hidden">
            <div class="flex items-center gap-1 min-w-0 flex-1 overflow-hidden">
              <span class="text-[10px] font-mono text-slate-500 shrink-0">${escapeHtml(hhmm)}</span>
              ${trophyHtmlCompact ? `<span class="shrink-0 inline-flex items-center">${trophyHtmlCompact}</span>` : ''}
              <span class="font-bold text-amber-400 text-xs truncate max-w-[130px]" title="${escapeHtml(nickname)}">${escapeHtml(nickname)}</span>
              ${t.admin_email ? `
                <a href="mailto:${escapeHtml(t.admin_email)}" class="inline-flex items-center text-xs hover:scale-125 transition-transform shrink-0 ml-0.5" title="ADMIN_EMAIL: ${escapeHtml(t.admin_email)}">
                  <img src="https://mailmeteor.com/logos/assets/PNG/Gmail_Logo_512px.png" class="w-3 h-3 inline-block opacity-90" alt="Gmail">
                </a>
              ` : ''}
            </div>

            <div class="shrink-0">
              ${stepBarHtml}
            </div>
          </div>
        </td>

        <!-- COLONNA 3: URL, JSON, Stack (Ruby/Rails) TUTTO IN UNA RIGA -->
        <td class="py-1 px-3 align-middle overflow-hidden whitespace-nowrap">
          <div class="flex items-center gap-2.5 min-w-0 overflow-hidden font-mono text-[11px]">
            <!-- Cloud Run Link -->
            <a href="${escapeHtml(student.url)}" target="_blank" rel="noopener noreferrer" class="text-sky-400 hover:text-sky-300 hover:underline flex items-center gap-1 truncate shrink-0 max-w-[210px]" title="${escapeHtml(student.url)}">
              <img src="/cloud_run_icon.png" class="w-3.5 h-3.5 object-contain shrink-0" alt="Cloud Run" title="Google Cloud Run">
              <span class="truncate font-medium">${escapeHtml(student.url.replace(/^https?:\/\//, ''))}</span>
            </a>

            <!-- JSON Link -->
            <a href="${escapeHtml(statusJsonUrl)}" target="_blank" rel="noopener noreferrer" class="inline-flex items-center hover:scale-125 transition-transform shrink-0" title="Inspect raw JSON (/status.json)">
              <img src="/json_icon.png" class="w-3.5 h-3.5 object-contain" alt="JSON">
            </a>

            <!-- Stack Badges (Ruby, Env, Rails, GCP Triad) -->
            ${hasTelemetry ? `
              <div class="flex items-center gap-1.5 shrink-0">
                <span class="inline-flex items-center gap-0.5 text-rose-300 font-medium" title="Ruby ${rubyVersion}">
                  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/ruby/ruby-original.svg" class="w-3 h-3 inline-block" alt="Ruby">
                  <span>${rubyVersion}</span>
                </span>
                ${envBadge}
                <span class="inline-flex items-center gap-0.5 text-red-300 font-medium" title="Rails ${railsVersion}">
                  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/rails/rails-plain.svg" class="w-3 h-3 inline-block" alt="Rails">
                  <span>${railsVersion}</span>
                </span>
                ${gcpTriadHtml}
              </div>
            ` : `
              <span class="text-[10px] text-slate-500 italic shrink-0">Awaiting stack...</span>
            `}

            <!-- Compact Metrics (Posts, Delta Rev) -->
            ${t.posts_count !== undefined ? `<span class="text-slate-400 text-[10px] shrink-0 border-l border-slate-800 pl-2">📝 ${t.posts_count}p</span>` : ''}
            ${jobsBadge}
            ${failedJobsBadge}
            ${deltaRevBadge}
          </div>
        </td>
      `;
    } else {
      tr.className = "hover:bg-slate-800/30 transition-colors";

      tr.innerHTML = `
        <!-- COLONNA 1: Live Dot + Sotto la latenza -->
        <td class="py-2 px-2.5 text-center whitespace-nowrap align-middle">
          <div class="flex flex-col items-center justify-center gap-0.5">
            ${dotHtml}
            ${latencyBadge}
          </div>
        </td>

        <!-- COLONNA 2: HH:MM [Medaglia/Coppa] Nome + Step Bar fissa a destra -->
        <td class="py-2.5 px-3 align-middle w-[320px] overflow-hidden">
          <div class="flex items-center justify-between gap-2 w-full overflow-hidden">
            <div class="flex items-center gap-1.5 min-w-0 flex-1 overflow-hidden">
              <span class="text-[11px] font-mono text-slate-400 font-medium shrink-0">${escapeHtml(hhmm)}</span>
              ${trophyHtml ? `<span class="shrink-0 inline-flex items-center text-sm">${trophyHtml}</span>` : ''}
              <span class="font-bold text-amber-400 text-sm truncate" title="${escapeHtml(nickname)}">${escapeHtml(nickname)}</span>
              ${t.admin_email ? `
                <a href="mailto:${escapeHtml(t.admin_email)}" class="inline-flex items-center text-xs hover:scale-125 transition-transform shrink-0 ml-0.5" title="⚠️ Publicly exposed ADMIN_EMAIL: ${escapeHtml(t.admin_email)} (Ask Antigravity about Secret Manager hardening!)">
                  <img src="https://mailmeteor.com/logos/assets/PNG/Gmail_Logo_512px.png" class="w-3.5 h-3.5 inline-block opacity-90 hover:opacity-100" alt="Gmail">
                </a>
              ` : ''}
            </div>

            <div class="shrink-0">
              ${stepBarHtml}
            </div>
          </div>
        </td>

        <!-- COLONNA 3: Riga 1 URL pulito con icona Cloud Run a sinistra; Riga 2 Stack Ruby/Rails + Metriche + JSON + Delta Revision -->
        <td class="py-2.5 px-4 align-middle overflow-hidden">
          <div class="flex flex-col gap-1 min-w-0">
            <!-- Riga 1: Icona Cloud Run a inizio URL + URL -->
            <div class="flex items-center gap-2 min-w-0">
              <a href="${escapeHtml(student.url)}" target="_blank" rel="noopener noreferrer" class="font-mono text-xs text-sky-400 hover:text-sky-300 hover:underline flex items-center gap-1.5 truncate max-w-full" title="${escapeHtml(student.url)}">
                <img src="/cloud_run_icon.png" class="w-4 h-4 object-contain inline-block drop-shadow-sm shrink-0" alt="Cloud Run" title="Google Cloud Run">
                <span class="font-medium truncate">${escapeHtml(student.url)}</span>
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
    }

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
