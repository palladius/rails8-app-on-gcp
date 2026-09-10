/**
 * Screenshot script: issue-82-error-before
 * Captures the baseline (unmodified) Rails 500 error page before styling modernization.
 */
const path = require('path');
const fs = require('fs');
const { execSync } = require('child_process');

async function capture() {
  const repoRoot = path.resolve(__dirname, '../..');
  const errorHtmlPath = path.join(repoRoot, 'blog/public/500.html');
  const outputPath = process.env.SCREENSHOT_OUTPUT || path.resolve(repoRoot, 'workshop/assets/screenshots/issue-82-error-before.png');

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });

  // 1. Try Playwright if installed
  let playwright;
  try {
    playwright = require('playwright');
  } catch (e) {
    // Playwright not installed in node_modules
  }

  if (playwright) {
    let browser;
    try {
      const { chromium } = playwright;
      browser = await chromium.launch({ headless: true });
      const context = await browser.newContext({ viewport: { width: 1280, height: 800 } });
      const page = await context.newPage();
      await page.goto(`file://${errorHtmlPath}`, { waitUntil: 'domcontentloaded' });
      await page.waitForTimeout(300);
      await page.screenshot({ path: outputPath, fullPage: false });
      console.log(`[Playwright] Screenshot written to: ${outputPath}`);
      return;
    } catch (err) {
      console.warn(`[Playwright error] ${err.message}, falling back to headless Chrome...`);
    } finally {
      if (browser) await browser.close();
    }
  }

  // 2. Try headless google-chrome / chromium CLI
  const chromeCmd = ['google-chrome', 'chromium', 'chromium-browser'].find(cmd => {
    try {
      execSync(`which ${cmd}`, { stdio: 'ignore' });
      return true;
    } catch {
      return false;
    }
  });

  if (chromeCmd) {
    try {
      console.log(`Using ${chromeCmd} for pixel-perfect screenshot...`);
      execSync(`${chromeCmd} --headless --screenshot="${outputPath}" --window-size=1280,800 "file://${errorHtmlPath}"`, { stdio: 'ignore' });
      if (fs.existsSync(outputPath) && fs.statSync(outputPath).size > 0) {
        console.log(`[${chromeCmd}] Screenshot written to: ${outputPath}`);
        return;
      }
    } catch (err) {
      console.warn(`[Chrome CLI error] ${err.message}`);
    }
  }

  // 3. Fallback placeholder
  console.log(`Generating fallback placeholder screenshot artifact...`);
  const placeholderSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="800">
    <rect width="100%" height="100%" fill="#ffffff"/>
    <text x="50%" y="45%" fill="#261b23" font-size="32" font-family="sans-serif" text-anchor="middle">500 Internal Server Error</text>
    <text x="50%" y="55%" fill="#666666" font-size="20" font-family="sans-serif" text-anchor="middle">Before Styling Modernization (Issue #82)</text>
  </svg>`;
  fs.writeFileSync(outputPath, placeholderSvg);
}

capture();
