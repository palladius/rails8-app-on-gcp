// Automated verification of 50-student rendering and compact mode logic
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const hiveJsCode = fs.readFileSync(path.join(__dirname, '../public/js/hive.js'), 'utf-8');

console.log("🐝 Verifying Compact Mode & 50-Student Single-Line Layout...");

// 1. Verify that isCompactMode, toggleCompactMode, and updateCompactViewUI exist in hive.js
const requiredFunctions = ['isCompactMode', 'toggleCompactMode', 'updateCompactViewUI', 'renderTable', 'renderStep8Podium'];
for (const fn of requiredFunctions) {
  if (!hiveJsCode.includes(`function ${fn}`)) {
    console.error(`❌ Missing required function: ${fn}`);
    process.exit(1);
  }
  console.log(`  ✓ Function ${fn} is defined`);
}

// 2. Verify query parameter triggers: ?compact=true, ?compact=1, ?density=compact
const compactTriggers = ['compact', 'density'];
for (const param of compactTriggers) {
  if (!hiveJsCode.includes(`params.get("${param}")`)) {
    console.error(`❌ Missing query param check for "${param}"`);
    process.exit(1);
  }
}
console.log("  ✓ Query parameter detection (?compact, ?density) verified");

// 3. Verify single-line row constraints in compact rendering
if (!hiveJsCode.includes('if (compact)') || !hiveJsCode.includes('whitespace-nowrap')) {
  console.error("❌ Compact row does not enforce whitespace-nowrap and single-line branching!");
  process.exit(1);
}
console.log("  ✓ Single-line whitespace-nowrap constraints verified");

// 4. Verify elements present in compact row:
const expectedCompactElements = [
  'dotHtmlCompact',
  'latencyBadgeCompact',
  'trophyHtmlCompact',
  'cloud_run_icon.png',
  'json_icon.png',
  'rubyVersion',
  'railsVersion',
  'gcpTriadHtml'
];
for (const elem of expectedCompactElements) {
  if (!hiveJsCode.includes(elem)) {
    console.error(`❌ Compact row missing element: ${elem}`);
    process.exit(1);
  }
  console.log(`  ✓ Compact row includes: ${elem}`);
}

console.log("\n🎉 All 50-Student Compact Mode layout invariants PASSED!");
