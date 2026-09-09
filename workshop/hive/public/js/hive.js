// Workshop Hive Table Client Logic — 5s Health & Telemetry Pings
let cachedLeaderboard = [];
let cachedHealth = {};

async function fetchLeaderboard() {
  try {
    const res = await fetch("/api/leaderboard");
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    cachedLeaderboard = data.entries || [];
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

    // Calcola apps sane
    const healthyCount = Object.values(cachedHealth).filter(c => c.status === "up").length;
    document.getElementById("stat-healthy-apps").textContent = healthyCount;

    // Aggiorna stato timestamp
    document.getElementById("sync-timer").textContent = new Date().toLocaleTimeString();
    renderTable();
  } catch (err) {
    console.error("Error fetching health checks:", err);
  }
}

function renderTable() {
  const tbody = document.getElementById("leaderboard-tbody");
  if (!tbody) return;

  if (cachedLeaderboard.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="7" class="py-12 text-center text-slate-500 italic">
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

    // Indicatore status a sinistra: rosso/verde lampeggiante
    let dotClass = "bg-slate-600";
    let statusText = "PING...";
    let statusBadge = "bg-slate-800 text-slate-400 border-slate-700";

    if (isUp) {
      dotClass = "bg-emerald-400 blink-up shadow-lg shadow-emerald-500/50";
      statusText = "UP";
      statusBadge = "bg-emerald-500/10 text-emerald-400 border-emerald-500/30";
    } else if (isDown) {
      dotClass = "bg-rose-500 blink-down shadow-lg shadow-rose-500/50";
      statusText = "DOWN";
      statusBadge = "bg-rose-500/10 text-rose-400 border-rose-500/30";
    }

    const latencyDisplay = check.latency_ms !== null && check.latency_ms !== undefined
      ? `${check.latency_ms} ms`
      : (check.http_code ? `HTTP ${check.http_code}` : "-");

    // Workshop Step: usa la telemetria live di /status se disponibile, altrimenti fallback a quella dichiarata
    const stepLabel = t.step_description || student.step || "Step 1: Local Baseline";
    const stepNumber = t.step_number || student.step_number || 1;

    // Stack: Ruby & Rails version
    const rubyVer = t.ruby_version ? `💎 Ruby ${t.ruby_version}` : "";
    const railsVer = t.rails_version ? `🛤️ Rails ${t.rails_version}` : "";
    const stackDisplay = (rubyVer || railsVer)
      ? `<div class="flex flex-col gap-0.5 font-mono text-xs">
           <span class="text-rose-300 font-semibold">${rubyVer}</span>
           <span class="text-red-400/90">${railsVer}</span>
         </div>`
      : `<span class="text-slate-600 font-mono text-xs italic">Unknown</span>`;

    // Metrics: Posts, Users, Images
    let metricsDisplay = "";
    if (t.posts_count !== undefined) {
      metricsDisplay = `
        <div class="flex items-center gap-3 font-mono text-xs">
          <span class="bg-slate-800 px-2 py-0.5 rounded border border-slate-700" title="Posts count">📝 <b class="text-amber-300">${t.posts_count}</b></span>
          <span class="bg-slate-800 px-2 py-0.5 rounded border border-slate-700" title="Admin users count">👤 <b class="text-sky-300">${t.users_count || 0}</b></span>
          <span class="bg-slate-800 px-2 py-0.5 rounded border border-slate-700" title="ActiveStorage Blobs">🖼️ <b class="text-emerald-300">${t.blobs_count || 0}</b></span>
        </div>
      `;
    } else {
      metricsDisplay = `<span class="text-slate-600 font-mono text-xs italic">Awaiting /status</span>`;
    }

    const tr = document.createElement("tr");
    tr.className = "hover:bg-slate-800/40 transition-colors";

    tr.innerHTML = `
      <!-- Status Blinking Dot on the Left -->
      <td class="py-4 pl-5 pr-2 text-center whitespace-nowrap">
        <div class="flex items-center justify-center">
          <span class="w-3.5 h-3.5 rounded-full ${dotClass} inline-block" title="${statusText}: ${escapeHtml(student.url)}"></span>
        </div>
      </td>

      <!-- Nickname -->
      <td class="py-4 px-4 whitespace-nowrap font-medium text-slate-100">
        <div class="flex items-center gap-2">
          <span class="text-base">👤</span>
          <span class="font-bold text-amber-300 text-base">${escapeHtml(student.nickname || "Anonymous")}</span>
        </div>
        <div class="text-[10px] text-slate-500 font-mono mt-0.5">${escapeHtml(student.timestamp || "")}</div>
      </td>

      <!-- Workshop Stage -->
      <td class="py-4 px-4 whitespace-nowrap">
        <div class="flex flex-col gap-1">
          <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-mono font-bold bg-amber-500/10 text-amber-300 border border-amber-500/20 w-max">
            Step ${stepNumber}
          </span>
          <span class="text-xs text-slate-300 font-medium">${escapeHtml(stepLabel)}</span>
        </div>
      </td>

      <!-- Stack (Ruby / Rails) -->
      <td class="py-4 px-4 whitespace-nowrap">
        ${stackDisplay}
      </td>

      <!-- Metrics (Posts / Users / Images) -->
      <td class="py-4 px-4 whitespace-nowrap">
        ${metricsDisplay}
      </td>

      <!-- Deployed App URL -->
      <td class="py-4 px-4">
        <a href="${escapeHtml(student.url)}" target="_blank" rel="noopener noreferrer" class="font-mono text-xs text-sky-400 hover:text-sky-300 hover:underline flex items-center gap-1.5 break-all">
          <span>🔗</span>
          <span>${escapeHtml(student.url)}</span>
        </a>
      </td>

      <!-- Last Ping / Latency -->
      <td class="py-4 px-4 pr-5 whitespace-nowrap text-right font-mono text-xs">
        <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded border ${statusBadge}">
          ${statusText} ${latencyDisplay !== "-" ? `· ${latencyDisplay}` : ""}
        </span>
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

// Initial fetch
fetchLeaderboard();
fetchHealth();

// Refresh health and rich telemetry every 5 seconds!
setInterval(fetchHealth, 5000);

// Refresh submissions every 15 seconds
setInterval(fetchLeaderboard, 15000);
