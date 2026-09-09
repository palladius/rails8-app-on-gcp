#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const repoRoot = path.resolve(__dirname, '../..');
const skeletonPath = path.join(repoRoot, 'workshop/skeleton.yaml');

function parseSimpleYaml(content) {
  // Minimal resilient parser for skeleton.yaml steps and screenshots without external dependencies
  const screenshots = [];
  const lines = content.split('\n');
  let currentStep = null;
  let inScreenshots = false;
  let currentShot = null;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const stepMatch = line.match(/^\s*-\s+id:\s*"([^"]+)"/);
    if (line.match(/^steps:/)) continue;
    const topStepMatch = line.match(/^  - id:\s*"([^"]+)"/);
    if (topStepMatch) {
      currentStep = topStepMatch[1];
      inScreenshots = false;
      currentShot = null;
    }
    if (line.match(/^\s{4}screenshots:/)) {
      inScreenshots = true;
      continue;
    }

    if (inScreenshots) {
      const shotStart = line.match(/^\s{6}-\s+id:\s*"([^"]+)"/);
      if (shotStart) {
        currentShot = { id: shotStart[1], step_id: currentStep };
        screenshots.push(currentShot);
        continue;
      }
      if (currentShot) {
        const propMatch = line.match(/^\s{8}([a-zA-Z_]+):\s*"?([^"\n]+)"?/);
        if (propMatch) {
          const key = propMatch[1];
          const val = propMatch[2].trim();
          currentShot[key] = isNaN(val) ? val : Number(val);
        }
      }
    }
  }
  return screenshots;
}

function loadScreenshots() {
  if (!fs.existsSync(skeletonPath)) {
    console.error(`Error: Skeleton file not found at ${skeletonPath}`);
    process.exit(1);
  }
  const content = fs.readFileSync(skeletonPath, 'utf8');
  return parseSimpleYaml(content);
}

const args = process.argv.slice(2);

if (args.includes('--list')) {
  const shots = loadScreenshots();
  console.log(JSON.stringify(shots, null, 2));
  process.exit(0);
}

if (args.includes('--dry-run')) {
  const shots = loadScreenshots();
  console.log(`🔍 Checking ${shots.length} declared screenshots in workshop/skeleton.yaml...`);
  let errors = 0;
  for (const shot of shots) {
    const scriptPath = path.join(repoRoot, shot.script);
    if (!fs.existsSync(scriptPath)) {
      console.error(`❌ Missing script for screenshot '${shot.id}': ${shot.script}`);
      errors++;
    } else {
      console.log(`✅ [${shot.step_id}] ${shot.id} -> ${shot.script} (Output: ${shot.output_path})`);
    }
  }
  if (errors > 0) {
    console.error(`❌ Validation failed with ${errors} missing scripts.`);
    process.exit(1);
  }
  console.log(`🎉 All ${shots.length} screenshot declarations and scripts are valid!`);
  process.exit(0);
}

// Execution mode
async function run() {
  const shots = loadScreenshots();
  const filter = args.find(a => !a.startsWith('--'));
  const targetShots = filter
    ? shots.filter(s => s.id === filter || s.step_id === filter || (s.step_id && s.step_id.includes(filter)))
    : shots;

  if (targetShots.length === 0) {
    console.log(`No screenshots matched filter '${filter}'. Available:`);
    shots.forEach(s => console.log(` - ${s.id} (${s.step_id})`));
    process.exit(0);
  }

  console.log(`📸 Executing ${targetShots.length} screenshot capture task(s)...`);
  for (const shot of targetShots) {
    const scriptPath = path.join(repoRoot, shot.script);
    const outputPath = path.join(repoRoot, shot.output_path);
    fs.mkdirSync(path.dirname(outputPath), { recursive: true });

    console.log(`\n▶️ Capturing [${shot.id}] via ${shot.script}...`);
    const env = {
      ...process.env,
      SCREENSHOT_ID: shot.id,
      SCREENSHOT_OUTPUT: outputPath,
      BASE_URL: process.env.BASE_URL || 'http://localhost:3000'
    };

    let result;
    if (scriptPath.endsWith('.js')) {
      result = spawnSync('node', [scriptPath], { env, stdio: 'inherit', cwd: repoRoot });
    } else if (scriptPath.endsWith('.rb')) {
      result = spawnSync('ruby', [scriptPath], { env, stdio: 'inherit', cwd: repoRoot });
    } else if (scriptPath.endsWith('.sh')) {
      result = spawnSync('bash', [scriptPath], { env, stdio: 'inherit', cwd: repoRoot });
    } else {
      console.error(`Unsupported script extension for ${scriptPath}`);
      continue;
    }

    if (result.status !== 0) {
      console.error(`⚠️ Failed to capture screenshot ${shot.id} (exit code: ${result.status})`);
    } else {
      console.log(`✅ Saved: ${shot.output_path}`);
    }
  }
}

run();
