import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { spawn, execSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const hiveDir = path.join(__dirname, '..');
const artifactDir = '/usr/local/google/home/ricc/.gemini/antigravity/brain/135899a9-07c5-445b-95b5-18efa3686c51';
const PORT = 8099;

console.log(`🚀 Starting local Hive app on port ${PORT}...`);
const server = spawn('ruby', ['-Ilib', 'app.rb'], {
  cwd: hiveDir,
  env: { ...process.env, PORT: String(PORT) },
  stdio: 'inherit'
});

// Allow server to boot
await new Promise(resolve => setTimeout(resolve, 2500));

try {
  for (const mode of ['full', 'compact']) {
    const isCompact = (mode === 'compact');
    const url = `http://localhost:${PORT}/?compact=${isCompact ? 'true' : 'false'}`;
    const screenshotPath = path.join(artifactDir, `hive_leaderboard_${mode}.png`);

    console.log(`📸 Capturing ${mode} view from ${url} -> ${screenshotPath}...`);
    // Give it a moment to render client-side DOM
    execSync(`google-chrome --headless=new --no-sandbox --disable-gpu --hide-scrollbars --window-size=1560,980 --virtual-time-budget=3000 --screenshot="${screenshotPath}" "${url}"`);
    console.log(`✓ Saved ${screenshotPath} (${fs.statSync(screenshotPath).size} bytes)`);
  }
} finally {
  console.log("🛑 Stopping local Hive server...");
  server.kill('SIGTERM');
}

console.log("\n🎉 Both screenshots captured successfully!");

