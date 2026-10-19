---
marp: true
theme: gaia
paginate: true
backgroundColor: #f5f5f5
color: #1a1a1a
style: |
  section {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    font-size: 23px;
    padding: 26px 46px;
    background-image: url('images/google-cloud-logo.svg');
    background-repeat: no-repeat;
    background-position: right 52px bottom 14px;
    background-size: 48px auto;
  }
  h1 {
    color: #1a73e8;
    font-size: 1.6em;
    margin: 0 0 0.18em 0;
  }
  h2 {
    color: #188038;
    font-size: 1.18em;
    margin: 0 0 0.25em 0;
  }
  h3 {
    font-size: 0.96em;
    margin: 0 0 0.18em 0;
    color: #202124;
  }
  p, ul, ol {
    margin: 0.18em 0;
    line-height: 1.32;
  }
  ul ul {
    margin: 0.08em 0;
  }
  footer {
    font-size: 0.55em;
    color: #5f6368;
  }
  code {
    background-color: #e8eaed;
    color: #c5221f;
    padding: 2px 5px;
    border-radius: 4px;
    font-size: 0.88em;
  }
  .card-grid-3 {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 14px;
    margin-top: 8px;
  }
  .card-stack {
    display: flex;
    flex-direction: column;
    gap: 10px;
    margin-top: 6px;
  }
  .card {
    background: white;
    border: 1px solid #dadce0;
    border-radius: 8px;
    padding: 10px 16px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.06);
    text-align: left;
  }
  .card-blue {
    border-left: 6px solid #1a73e8;
  }
  .card-green {
    border-left: 6px solid #188038;
  }
  .card-yellow {
    border-left: 6px solid #f9ab00;
  }
  .card-red {
    border-left: 6px solid #d93025;
    background-color: #fce8e6;
  }
  .badge {
    display: inline-block;
    padding: 3px 9px;
    border-radius: 12px;
    font-size: 0.68em;
    font-weight: bold;
    color: white;
    vertical-align: middle;
  }
  .badge-blue { background-color: #1a73e8; }
  .badge-green { background-color: #1e8e3e; }
  .badge-yellow { background-color: #f9ab00; color: #202124; }
  .badge-red { background-color: #d93025; }
  .highlight-banner {
    background-color: #e8f0fe;
    border-left: 5px solid #1a73e8;
    padding: 8px 14px;
    border-radius: 6px;
    font-size: 0.8em;
    margin-top: 10px;
    text-align: left;
  }
  .warning-banner {
    background-color: #fef7e0;
    border: 1px solid #f9ab00;
    border-left: 6px solid #ea8600;
    padding: 8px 14px;
    border-radius: 6px;
    font-size: 0.8em;
    color: #3c4043;
    margin-top: 8px;
    text-align: left;
  }
---

## 🎓 Qwiklabs Edition: What's Different in Qwiklabs? <span class="badge badge-blue">ce526-rails8-on-google-cloud v0.3.7</span>

<div class="card-stack">

<div class="card card-blue">
  <h3 style="color: #1a73e8;">🖥️ 100% Inside the Antigravity Remote Session (KDE Webtop)</h3>
  <p style="font-size: 0.82em; color: #3c4043; margin: 0;">
    Everything runs in <strong>ONE browser tab</strong> (<code>Konsole</code> + <code>Antigravity App</code> + remote <code>Chrome</code> already signed in as <code>student-...</code>).<br/>
    <strong>No Cloud Shell needed!</strong> Open the Remote Session link and stay inside it for the entire workshop.
  </p>
</div>

<div class="card card-yellow">
  <h3 style="color: #b06000;">🐳 No Local Docker (<code>Docker-in-Docker</code> Limitation)</h3>
  <p style="font-size: 0.82em; color: #3c4043; margin: 0;">
    The Remote Session is already a Docker container and port <code>3000</code> is reserved for the Webtop UI!<br/>
    &bull; <strong>Step 2 (Local Dev):</strong> Run Rails 8 natively on SQLite (<code>PORT=3002 bin/dev</code> &rarr; <code>http://localhost:3002</code>).<br/>
    &bull; <strong>Steps 3, 4, 6 (Deploy):</strong> Build remotely on <strong>Cloud Build</strong> (<code>gcloud run deploy --source .</code> / <code>gcloud run compose up</code>).
  </p>
</div>

<div class="card card-green">
  <h3 style="color: #188038;">🧰 Zero-Install Workstation (Pre-Configured &amp; Ready!)</h3>
  <p style="font-size: 0.82em; color: #3c4043; margin: 0;">
    Pre-installed <code>ruby 3.4.5</code> (<code>/opt/hostedtoolcache</code>), <code>terraform 1.9.8</code>, <code>just 1.45</code>, <code>cloud-sql-proxy 2.14</code>, <code>gcloud</code> (<code>run-compose</code>), and <code>~/rails8-app-on-gcp</code> with <code>.env</code> &amp; <code>blog/.env</code> <strong>pre-populated</strong>!
  </p>
</div>

</div>

<div class="highlight-banner">
  💡 <strong>Self-Paced Tip:</strong> Follow the Qwiklabs instructions tab alongside your Remote Session, or ask <strong>Antigravity App</strong> to guide you step by step!
</div>

---

## ⏱️ Qwiklabs Edition: The 3-Phase Startup Timeline

<p style="font-size: 0.82em; color: #5f6368; margin: 0 0 6px 0;">
  📊 Empirical timeline measured from clicking <strong>Start Lab (<code>T+0m00s</code>)</strong> on <code>ce526-rails8-on-google-cloud</code>:
</p>

<div class="card-stack">

<div class="card card-blue">
  <div style="display: flex; justify-content: space-between; align-items: center;">
    <h3 style="color: #1a73e8; margin: 0;">1️⃣ Phase 1: Qwiklabs Infrastructure Provisioning</h3>
    <span class="badge badge-blue">T+0m &rarr; T+7m (~6–7 min)</span>
  </div>
  <p style="font-size: 0.8em; color: #3c4043; margin: 4px 0 0 0;">
    Creates the GCP Project, <code>ce-workstation</code> GCE VM, and <code>remote-browser-vm1</code> Cloud Run proxy (<code>04:00:00</code> resource timer starts!).
  </p>
</div>

<div class="card card-yellow">
  <div style="display: flex; justify-content: space-between; align-items: center;">
    <h3 style="color: #b06000; margin: 0;">2️⃣ Phase 2: In-VM Container Boot &amp; <code>ag_autologin.py</code> ("Ghost in the Shell")</h3>
    <span class="badge badge-yellow">T+7m &rarr; T+11m (~4 min)</span>
  </div>
  <p style="font-size: 0.8em; color: #3c4043; margin: 4px 0 0 0;">
    Boots the KDE container and visibly drives the GUI: signs into Chrome, configures Antigravity App (<em>General &rarr; Always proceed</em>), and opens <code>/config/rails8-app-on-gcp</code> maximized (<code>~03:55:30</code> on the 4h timer).
  </p>
</div>

<div class="card card-green">
  <div style="display: flex; justify-content: space-between; align-items: center;">
    <h3 style="color: #188038; margin: 0;">3️⃣ Phase 3: Auto <code>bundle install</code> + Auto <code>just terraform-apply</code> Pre-Warming</h3>
    <span class="badge badge-green">T+11m &rarr; T+23m (Background!)</span>
  </div>
  <p style="font-size: 0.8em; color: #3c4043; margin: 4px 0 0 0;">
    Runs unattended in background right after Auto-Login via GCE Metadata Server (<code>antigravity-sa</code>) while you read Step 0!
  </p>
</div>

</div>

<div class="card card-red" style="margin-top: 8px; padding: 8px 14px;">
  <p style="font-size: 0.82em; color: #a50e0e; margin: 0; font-weight: bold;">
    🙌 HANDS OFF MOUSE &amp; KEYBOARD UNTIL ANTIGRAVITY IS MAXIMIZED! (Phase 2) — Let the "Ghost in the Shell" finish typing your credentials and opening the repo!
  </p>
</div>

---

## 🔒 Qwiklabs Edition: Auto-Terraform &amp; Zero-Collision Lock (`v0.3.7`)

<div class="card-stack">

<div class="card card-green">
  <h3 style="color: #188038;">🚀 Pre-Warmed Infrastructure (Sequential CPU Priority)</h3>
  <p style="font-size: 0.82em; color: #3c4043; margin: 0;">
    <code>startup.sh</code> launches <code>iac/bin/terraform-apply.sh</code> in the background (<code>~/rails8-app-on-gcp/log/terraform-startup.log</code>) <strong>right after</strong> <code>ag_autologin.py</code> finishes — so GUI auto-login gets <strong>100% CPU first</strong>!
  </p>
</div>

<div class="card card-blue">
  <h3 style="color: #1a73e8;">🔒 Zero-Collision GCS State Lock (<code>TF_CLI_ARGS_apply="-lock-timeout=15m"</code>)</h3>
  <p style="font-size: 0.82em; color: #3c4043; margin: 0 0 4px 0;">
    Whether you are fast or slow, <code>just terraform-apply</code> in Step 1 is 100% safe and idempotent:
  </p>
  <ul style="font-size: 0.8em; color: #3c4043; margin: 0;">
    <li>⚡ <strong>Run <em>after</em> background job finishes:</strong> Completes in <strong>~5 seconds</strong> (<code>0 added, 0 changed, 0 destroyed</code>)!</li>
    <li>⏳ <strong>Run <em>while</em> Cloud SQL is still provisioning:</strong> Waits cleanly on the <code>gs://${PROJECT_ID}-tfstate</code> lock and finishes immediately after!</li>
  </ul>
</div>

<div class="card card-yellow">
  <h3 style="color: #b06000;">☁️ Two Cloud Run Services in Cloud Console</h3>
  <p style="font-size: 0.82em; color: #3c4043; margin: 0;">
    In Cloud Console you will see <strong>two</strong> Cloud Run services:<br/>
    1. 🛑 <code>remote-browser-vm1</code> — Your Qwiklabs KDE desktop proxy (<strong>DO NOT TOUCH / DELETE!</strong>)<br/>
    2. 🚀 <code>*-rails-app</code> — Your Rails 8 production application!
  </p>
</div>

</div>

<div class="warning-banner">
  🔍 <strong>Want to watch background Terraform live?</strong> Run <code>tail -f ~/rails8-app-on-gcp/log/terraform-startup.log</code> in Konsole!
</div>
