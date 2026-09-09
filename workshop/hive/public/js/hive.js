// Workshop Hive Client Logic
const STEPS = [
  { id: 1, title: "Step 1: Local Baseline", icon: "💻" },
  { id: 2, title: "Step 2: Docker Compose", icon: "🐳" },
  { id: 3, title: "Step 3: Cloud SQL Proxy", icon: "🐘" },
  { id: 4, title: "Step 4: GCS Storage", icon: "📦" },
  { id: 5, title: "Step 5: Cloud Run Deploy", icon: "🚀" },
  { id: 6, title: "Step 6: Solid Queue Worker", icon: "⚡" },
  { id: 7, title: "Step 7: Vertex AI Nano Banana", icon: "🍌" }
];

let cachedLeaderboard = [];
let cachedHealth = {};

async function fetchLeaderboard() {
  try {
    const res = await fetch("/api/leaderboard");
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    cachedLeaderboard = data.entries || [];
    document.getElementById("stat-total-students").textContent = cachedLeaderboard.length;
    renderBoard();
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
    renderBoard();
  } catch (err) {
    console.error("Error fetching health checks:", err);
  }
}

function renderBoard() {
  const container = document.getElementById("kanban-board");
  if (!container) return;

  container.innerHTML = "";

  STEPS.forEach(step => {
    const studentsInStep = cachedLeaderboard.filter(s => s.step_number === step.id);

    const col = document.createElement("div");
    col.className = "flex-shrink-0 w-80 bg-slate-900/90 rounded-xl border border-slate-800 flex flex-col max-h-full shadow-lg";

    // Column Header
    col.innerHTML = `
      <div class="p-4 border-b border-slate-800 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <span class="text-xl">${step.icon}</span>
          <h3 class="font-bold text-sm text-slate-200">${step.title}</h3>
        </div>
        <span class="px-2 py-0.5 text-xs font-mono rounded-full bg-slate-800 text-slate-400 font-semibold">
          ${studentsInStep.length}
        </span>
      </div>
      <div class="p-3 flex-1 overflow-y-auto flex flex-col gap-2.5" id="step-col-${step.id}">
      </div>
    `;

    const cardsContainer = col.querySelector(`#step-col-${step.id}`);

    if (studentsInStep.length === 0) {
      cardsContainer.innerHTML = `
        <div class="p-6 text-center text-xs text-slate-600 italic">
          No students yet in this stage
        </div>
      `;
    } else {
      studentsInStep.forEach(student => {
        const health = cachedHealth[student.url] || { status: "unknown", latency_ms: null };
        const isUp = health.status === "up";
        const isDown = health.status === "down";

        const badgeClass = isUp
          ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/30"
          : isDown
          ? "bg-rose-500/10 text-rose-400 border-rose-500/30"
          : "bg-slate-800 text-slate-400 border-slate-700";

        const blinkClass = isUp ? "bg-emerald-400 blink-up" : isDown ? "bg-rose-500 blink-down" : "bg-slate-500";

        const latencyText = health.latency_ms ? `${health.latency_ms}ms` : "";

        const card = document.createElement("div");
        card.className = "p-3.5 bg-slate-950/70 rounded-lg border border-slate-800/80 hover:border-amber-500/40 transition-all flex flex-col gap-2";

        card.innerHTML = `
          <div class="flex items-center justify-between">
            <span class="font-bold text-sm text-amber-300 flex items-center gap-1.5">
              👤 ${escapeHtml(student.nickname || "Anonymous Student")}
            </span>
            <span class="inline-flex items-center gap-1.5 px-2 py-0.5 text-xs rounded-full border ${badgeClass}">
              <span class="w-1.5 h-1.5 rounded-full ${blinkClass}"></span>
              <span class="font-mono text-[10px] uppercase font-bold">${health.status || "WAIT"}</span>
              ${latencyText ? `<span class="text-[9px] opacity-75">(${latencyText})</span>` : ""}
            </span>
          </div>

          <div class="flex items-center justify-between text-xs text-slate-400 mt-1">
            <a href="${escapeHtml(student.url)}" target="_blank" rel="noopener noreferrer" class="hover:text-amber-400 underline truncate max-w-[200px]" title="${escapeHtml(student.url)}">
              🔗 ${escapeHtml(student.url)}
            </a>
            <span class="text-[10px] text-slate-500 font-mono">
              ${formatTime(student.timestamp)}
            </span>
          </div>
        `;
        cardsContainer.appendChild(card);
      });
    }

    container.appendChild(col);
  });
}

function escapeHtml(str) {
  if (!str) return "";
  return str.replace(/[&<>"']/g, function(m) {
    return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[m];
  });
}

function formatTime(iso) {
  if (!iso) return "";
  try {
    const d = new Date(iso);
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  } catch {
    return "";
  }
}

// Polling loop
async function refreshAll() {
  await fetchLeaderboard();
  await fetchHealth();
}

refreshAll();
setInterval(refreshAll, 10000); // Poll every 10 seconds
