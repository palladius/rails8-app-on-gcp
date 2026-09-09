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

    const healthyCount = Object.values(cachedHealth).filter(c => c.status === "up").length;
    document.getElementById("stat-healthy-apps").textContent = healthyCount;
    document.getElementById("sync-timer").textContent = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });

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
        <td colspan="7" class="py-12 text-center text-slate-500 italic font-mono text-xs">
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

    // Indicator Dot (pill with glow)
    let dotHtml = `<span class="w-3 h-3 rounded-full bg-slate-700 inline-block"></span>`;
    if (isUp) {
      dotHtml = `<span class="w-3 h-3 rounded-full bg-emerald-400 blink-up inline-block ring-2 ring-emerald-500/30" title="200 OK"></span>`;
    } else if (isDown) {
      dotHtml = `<span class="w-3 h-3 rounded-full bg-rose-500 blink-down inline-block ring-2 ring-rose-500/30" title="DOWN"></span>`;
    }

    // Step Badge
    const stepNum = t.step_number || student.step_number || 1;
    const stepText = t.step_description ? t.step_description.replace(/Step \d+:\s*/, "") : (student.step || `Step ${stepNum}`);

    // Stack display
    let stackHtml = `<span class="text-slate-500 text-xs italic font-mono">-</span>`;
    if (t.ruby_version || t.rails_version) {
      stackHtml = `
        <div class="flex items-center gap-2 text-xs font-mono">
          ${t.ruby_version ? `<span class="text-rose-400 bg-rose-950/40 px-1.5 py-0.5 rounded border border-rose-800/40">💎 ${t.ruby_version}</span>` : ""}
          ${t.rails_version ? `<span class="text-red-400 bg-red-950/40 px-1.5 py-0.5 rounded border border-red-800/40">🛤️ ${t.rails_version}</span>` : ""}
        </div>
      `;
    }

    // Metrics display
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

    // URL formatting - clean single line truncation
    const cleanUrl = student.url.replace(/^https?:\/\//, "").replace(/\/$/, "");
    const urlDisplay = `
      <a href="${escapeHtml(student.url)}" target="_blank" rel="noopener noreferrer" class="inline-flex items-center gap-1.5 font-mono text-xs text-sky-400 hover:text-sky-300 hover:underline max-w-[280px] truncate" title="${escapeHtml(student.url)}">
        <span class="opacity-70">🔗</span>
        <span class="truncate">${escapeHtml(cleanUrl)}</span>
      </a>
    `;

    // Latency
    const latencyBadge = isUp
      ? `<span class="font-mono text-xs font-medium text-emerald-400 bg-emerald-950/50 px-2 py-0.5 rounded border border-emerald-800/50">${check.latency_ms} ms</span>`
      : isDown
      ? `<span class="font-mono text-xs font-medium text-rose-400 bg-rose-950/50 px-2 py-0.5 rounded border border-rose-800/50">${check.http_code ? 'HTTP ' + check.http_code : 'FAIL'}</span>`
      : `<span class="font-mono text-xs text-slate-500">-</span>`;

    const tr = document.createElement("tr");
    tr.className = "hover:bg-slate-800/30 transition-colors";

    tr.innerHTML = `
      <!-- Live Indicator -->
      <td class="py-3.5 px-4 text-center whitespace-nowrap">
        <div class="flex items-center justify-center">
          ${dotHtml}
        </div>
      </td>

      <!-- Nickname & Timestamp -->
      <td class="py-3.5 px-5 whitespace-nowrap">
        <div class="font-semibold text-slate-100 flex items-center gap-1.5">
          <span class="text-amber-400">${escapeHtml(student.nickname || "Anonymous")}</span>
        </div>
        <div class="text-[10px] text-slate-500 font-mono mt-0.5">${escapeHtml(student.timestamp || "")}</div>
      </td>

      <!-- Workshop Step -->
      <td class="py-3.5 px-5 whitespace-nowrap">
        <div class="flex items-center gap-2">
          <span class="px-2 py-0.5 rounded text-[11px] font-mono font-bold bg-amber-500/10 text-amber-300 border border-amber-500/30">
            Step ${stepNum}
          </span>
          <span class="text-xs text-slate-300 truncate max-w-[160px]" title="${escapeHtml(stepText)}">
            ${escapeHtml(stepText)}
          </span>
        </div>
      </td>

      <!-- Stack -->
      <td class="py-3.5 px-5 whitespace-nowrap">
        ${stackHtml}
      </td>

      <!-- Metrics -->
      <td class="py-3.5 px-5 whitespace-nowrap">
        ${metricsHtml}
      </td>

      <!-- URL (No vertical wrapping) -->
      <td class="py-3.5 px-5 whitespace-nowrap">
        ${urlDisplay}
      </td>

      <!-- Latency -->
      <td class="py-3.5 px-5 whitespace-nowrap text-right">
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

// Initial triggers
fetchLeaderboard();
fetchHealth();

// Refresh health every 5 seconds
setInterval(fetchHealth, 5000);

// Refresh submissions every 15 seconds
setInterval(fetchLeaderboard, 15000);
