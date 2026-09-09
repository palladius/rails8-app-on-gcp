/**
 * Screenshot script: step-4-gcs-stuck-jobs-warning
 * Captures Cloud Run UI with GCS private blob and the pedagogical stuck jobs warning banner.
 */
const path = require('path');
const fs = require('fs');

async function capture() {
  const baseUrl = process.env.BASE_URL || 'http://localhost:3000';
  const outputPath = process.env.SCREENSHOT_OUTPUT || path.resolve(__dirname, '../assets/auto-screenshots/step-4-gcs-stuck-jobs-warning.png');

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });

  let playwright;
  try {
    playwright = require('playwright');
  } catch (e) {
    console.warn(`[Playwright not installed in local node_modules] To capture live browser screenshots, run: (cd workshop && npm install). Falling back to mock / placeholder generation.`);
  }

  let browser;
  try {
    if (!playwright) {
      throw new Error("Playwright module not loaded");
    }
    const { chromium } = playwright;
    browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({
      viewport: { width: 1280, height: 800 }
    });
    const page = await context.newPage();

    console.log(`Navigating to ${baseUrl}...`);
    await page.goto(baseUrl, { timeout: 8000, waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(500);

    await page.screenshot({ path: outputPath, fullPage: false });
    console.log(`Screenshot written to: ${outputPath}`);
  } catch (err) {
    console.warn(`[Dry-Run or Offline Fallback] Could not reach ${baseUrl} (${err.message}).`);
    if (!fs.existsSync(outputPath)) {
      console.log(`Generating placeholder screenshot artifact...`);
      const placeholderSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="800">
        <rect width="100%" height="100%" fill="#0f3460"/>
        <text x="50%" y="45%" fill="#f39c12" font-size="32" font-family="sans-serif" text-anchor="middle">Rails 8 on GCP Workshop - Step 4</text>
        <text x="50%" y="55%" fill="#ffffff" font-size="20" font-family="sans-serif" text-anchor="middle">[GCS STORAGE] Stuck Jobs Warning Active</text>
      </svg>`;
      fs.writeFileSync(outputPath, placeholderSvg);
    }
  } finally {
    if (browser) await browser.close();
  }
}

capture();
