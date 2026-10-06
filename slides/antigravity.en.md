---
marp: true
theme: gaia
_class: lead
paginate: true
backgroundColor: #f5f5f5
color: #1a1a1a
style: |
  section {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    font-size: 24px;
    padding: 24px 44px;
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
    font-size: 1.22em;
    margin: 0 0 0.2em 0;
  }
  h3 {
    font-size: 1.0em;
    margin: 0 0 0.2em 0;
    color: #3c4043;
  }
  p, ul, ol {
    margin: 0.2em 0;
    line-height: 1.32;
  }
  ul ul {
    margin: 0.1em 0;
  }
  footer {
    font-size: 0.55em;
    color: #5f6368;
  }
  pre {
    margin: 0.3em 0;
    font-size: 0.65em;
    padding: 10px;
  }
  .highlight {
    background-color: #e8f0fe;
    border-left: 5px solid #1a73e8;
    padding: 8px 14px;
    border-radius: 4px;
    font-size: 0.84em;
    margin-top: 0.3em;
  }
  .disclaimer-box {
    background-color: #fce8e6;
    border-left: 6px solid #d93025;
    border: 1px solid #f28b82;
    border-left-width: 6px;
    padding: 8px 14px;
    border-radius: 6px;
    font-size: 0.76em;
    color: #a50e0e;
    margin-top: 8px;
    line-height: 1.28;
  }
  .prompt-box {
    background-color: #202124;
    color: #e8eaed;
    padding: 14px 18px;
    border-radius: 8px;
    font-family: monospace;
    font-size: 0.84em;
    line-height: 1.4;
    margin: 0.35em 0;
  }
  .badge {
    display: inline-block;
    padding: 3px 8px;
    border-radius: 12px;
    font-size: 0.7em;
    font-weight: bold;
    color: white;
  }
  .badge-blue { background-color: #1a73e8; }
  .badge-green { background-color: #1e8e3e; }
  .badge-yellow { background-color: #f9ab00; color: #202124; }
  .two-col {
    display: flex;
    gap: 18px;
    align-items: stretch;
    margin-top: 6px;
  }
  .col-half {
    flex: 1;
    background: white;
    padding: 10px 12px;
    border-radius: 8px;
    border: 1px solid #dadce0;
    box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    display: flex;
    flex-direction: column;
    justify-content: space-between;
  }
  .col-half img {
    width: 100%;
    max-height: 375px;
    object-fit: contain;
    border-radius: 6px;
    border: 1px solid #e0e0e0;
    margin-top: 6px;
  }
  .slide5-container {
    display: flex;
    gap: 20px;
    align-items: center;
    margin-top: 6px;
  }
  .slide5-col-left {
    flex: 1;
  }
  .slide5-col-right {
    flex: 0 0 560px;
    text-align: center;
  }
  .slide5-col-right img {
    width: 100%;
    max-height: 470px;
    object-fit: contain;
    border-radius: 8px;
    border: 1px solid #dadce0;
    box-shadow: 0 4px 14px rgba(0,0,0,0.15);
  }
  .btn-copy {
    margin-top: 6px;
    background-color: #1a73e8;
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 6px;
    cursor: pointer;
    font-size: 0.78em;
    font-weight: bold;
    display: inline-flex;
    align-items: center;
    gap: 4px;
  }
---

# Zero to Cloud with Antigravity 2.0 🚀
### Building & Deploying Rails 8 on Google Cloud (Wednesday Build Hour)

<a href="antigravity.it.html" title="Versione Italiana" style="position: absolute; top: 12px; right: 16px; font-size: 0.7em; text-decoration: none; opacity: 0.82;">🇮🇹</a>
<div style="position: absolute; top: 34px; right: 42px; text-align: center; background: white; padding: 6px 8px 4px 8px; border-radius: 8px; border: 1px solid #dadce0; box-shadow: 0 2px 8px rgba(0,0,0,0.08);">
<img src="images/slides-qr.png" style="width: 104px; height: 104px; display: block;" alt="Slides QR Code" />
<span style="font-size: 0.44em; color: #5f6368; font-weight: bold; display: block; margin-top: 2px;">📱 Slides Link</span>
</div>

<div style="text-align: center; margin: 6px 0;">
<img src="images/slide1-style1-pixar.png" style="max-height: 430px; border-radius: 10px; box-shadow: 0 4px 16px rgba(0,0,0,0.15);" />
</div>

<p style="text-align: center; font-size: 0.82em; margin: 4px 0 0 0;">
<strong>Riccardo Carlesso</strong> 🦖 &amp; <strong>Emiliano Della Casa</strong> 🍝🏎️ &nbsp;&middot;&nbsp; <em>Google Cloud DevRel &amp; Open Source</em>
</p>

<div style="position: absolute; bottom: 14px; left: 35px; display: flex; align-items: center; gap: 8px;">
<img src="images/riccardo-carlesso.webp" style="width: 48px; height: 48px; border-radius: 50%; object-fit: cover; border: 2px solid #1a73e8; box-shadow: 0 2px 6px rgba(0,0,0,0.15);" alt="Riccardo" />
<img src="images/emiliano-della-casa.png" style="width: 48px; height: 48px; border-radius: 50%; object-fit: cover; border: 2px solid #188038; box-shadow: 0 2px 6px rgba(0,0,0,0.15);" alt="Emiliano" />
</div>

---

## Step 1: Download & Install Google Antigravity 2.0 ⬇️

<div class="two-col" style="align-items: center; margin-top: 8px; gap: 22px;">
<div style="flex: 0 0 38%; display: flex; flex-direction: column; gap: 12px;">
<div>
<a href="https://antigravity.google/download" target="_blank" rel="noopener noreferrer" style="display: inline-block; background-color: #1a73e8; color: white; padding: 10px 20px; border-radius: 6px; text-decoration: none; font-weight: bold; font-size: 0.92em;">
🚀 Download Antigravity 2.0
</a>
</div>
<p style="font-size: 0.82em; color: #3c4043; margin: 0;">
🔗 <a href="https://antigravity.google/download" target="_blank" rel="noopener noreferrer" style="color: #1a73e8; text-decoration: none; font-weight: bold;">antigravity.google/download</a>
</p>
<div class="highlight" style="font-size: 0.84em; padding: 12px 14px; margin-top: 4px;">
<p>🪟 <strong>Windows Users Tip:</strong> Please use <strong>WSL (Windows Subsystem for Linux)</strong> — it makes Ruby, Docker, and Linux tooling 10x easier!</p>
</div>
</div>
<div style="flex: 1; text-align: center;">
<img src="images/antigravity-download.png" style="max-height: 510px; width: 100%; object-fit: contain; border-radius: 8px; box-shadow: 0 6px 18px rgba(0,0,0,0.14); border: 1px solid #dadce0;" alt="Download Antigravity 2.0" />
</div>
</div>

---

## Step 1.5: Open the Official Google Codelab (Page 1 &rarr; `#0`) 📖

<div class="two-col" style="align-items: center; margin-top: 2px; gap: 20px;">
<div style="flex: 0 0 41%; display: flex; flex-direction: column; gap: 10px;">
<div>
<a href="https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud#0" target="_blank" rel="noopener noreferrer" style="display: inline-block; background-color: #1a73e8; color: white; padding: 9px 18px; border-radius: 6px; text-decoration: none; font-weight: bold; font-size: 0.88em;">
📖 Open Official Codelab (#0)
</a>
</div>
<ul style="font-size: 0.8em; margin: 0; padding-left: 20px; line-height: 1.4;">
<li>⏳ <strong>While Antigravity downloads:</strong> open the Codelab in <strong>Google Chrome</strong>!</li>
<li>🔢 <strong>Page 1 (<code>#0</code>):</strong> Introduction &amp; Architecture Overview.</li>
<li>💳 <strong>Page 2 (<code>#1</code>):</strong> Prerequisites &amp; <strong>Free GCP Credits</strong> (we'll claim them in Step 6!).</li>
</ul>
<div style="display: flex; align-items: center; gap: 14px; margin-top: 4px; background: white; padding: 12px 14px; border-radius: 8px; border: 1px solid #dadce0; box-shadow: 0 2px 8px rgba(0,0,0,0.06);">
<img src="images/codelab-qr.png" style="width: 155px; height: 155px; border-radius: 6px; border: 1px solid #dadce0;" alt="Codelab QR Code" />
<span style="font-size: 0.7em; color: #5f6368; line-height: 1.38;">📱 <strong>Scan QR to open Codelab</strong><br/><a href="https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud#0" target="_blank" rel="noopener noreferrer" style="color: #1a73e8; word-break: break-all;">codelabs.developers.google.com/codelabs/rails8-on-google-cloud#0</a></span>
</div>
</div>
<div style="flex: 1; text-align: center;">
<img src="images/codelab-page1-intro.png" style="max-height: 555px; width: 100%; object-fit: contain; border-radius: 8px; border: 1px solid #dadce0; box-shadow: 0 6px 20px rgba(0,0,0,0.18);" alt="Google Codelab Page 1 (#0) Introduction" />
</div>
</div>

---

## Step 2: Launch & Sign In with Gmail 🔐

1. Open **Google Antigravity 2.0** &nbsp;&middot;&nbsp; 2. Click **Sign in with Google** &nbsp;&middot;&nbsp; 3. Authorize your agent.

<div style="text-align: center; margin: 6px 0;">
<img src="images/antigravity-login.png" style="max-height: 475px; border-radius: 8px; box-shadow: 0 4px 16px rgba(0,0,0,0.25); border: 1px solid #3c4043;" alt="Sign in with Google" />
</div>

<p style="font-size: 0.82em; color: #3c4043; text-align: center; margin: 4px 0 0 0;">
💡 Sign in with your personal <code>@gmail.com</code> account (the same one you will use to claim GCP credits).
</p>

---

## Step 3: Prompt 1 — Clone the Repository into `Documents` 📥

Paste this **first prompt** into any Antigravity chat window to clone the workshop repo and chime when ready:

<div class="prompt-box" style="font-size: 0.92em; padding: 18px 22px; margin: 12px 0;">
Download https://github.com/palladius/rails8-app-on-gcp/ (via git clone) into my Documents folder and play a short sound when you are done.
</div>

<button class="btn-copy" style="font-size: 0.86em; padding: 10px 20px;" onclick="navigator.clipboard.writeText('Download https://github.com/palladius/rails8-app-on-gcp/ (via git clone) into my Documents folder and play a short sound when you are done.'); this.innerText='✅ Copied!'; setTimeout(() => this.innerText='📋 Copy Prompt 1 (Clone Repo)', 2000)">📋 Copy Prompt 1 (Clone Repo)</button>

<div class="highlight" style="margin-top: 18px; font-size: 0.9em; padding: 12px 18px;">
<p>🤖 <strong>Why do this via prompt?</strong> Antigravity verifies <code>git</code> is installed, clones <code>rails8-app-on-gcp</code> straight into <code>~/Documents/rails8-app-on-gcp</code>, and plays an audio chime when finished!</p>
</div>

---

## Step 4a: Open a New Project Inside `Documents/rails8-app-on-gcp` 📁

<div style="display: flex; flex-direction: column; gap: 12px; margin-top: 4px;">
<div class="col-half" style="flex-direction: row; align-items: center; gap: 16px; padding: 10px 14px;">
<div style="flex: 0 0 30%;">
<p style="font-size: 0.84em; margin: 0;"><strong>1️⃣ Click <code>New Project</code> (Select a folder)</strong><br/><span style="color: #5f6368; font-size: 0.9em;">In the top-left <strong>Projects</strong> sidebar, click the folder+ icon and pick <strong>New Project</strong>.</span></p>
</div>
<div style="flex: 1; text-align: right;">
<img src="images/agy-step1-new-project.png" style="max-height: 220px; width: 100%; object-fit: contain;" alt="Step 1: Click New Project in Antigravity" />
</div>
</div>
<div class="col-half" style="flex-direction: row; align-items: center; gap: 16px; padding: 10px 14px;">
<div style="flex: 0 0 30%;">
<p style="font-size: 0.84em; margin: 0;"><strong>2️⃣ Select <code>Documents/rails8-app-on-gcp</code></strong><br/><span style="color: #5f6368; font-size: 0.9em;">Navigate to <strong>Home / Documents</strong> and select the cloned <code>rails8-app-on-gcp</code> folder.</span></p>
</div>
<div style="flex: 1; text-align: right;">
<img src="images/agy-step2-select-folder.png" style="max-height: 290px; width: 100%; object-fit: contain;" alt="Step 2: Select Documents/rails8-app-on-gcp folder" />
</div>
</div>
</div>

---

## Step 4b: Say `"ciao"` & Enable TURBO Mode ⚡

<div class="two-col" style="align-items: center; margin-top: 4px; gap: 18px;">
<div style="flex: 0 0 47%; display: flex; flex-direction: column; gap: 10px;">
<div class="col-half" style="justify-content: flex-start; padding: 10px 12px;">
<p style="font-size: 0.78em; margin: 0 0 6px 0;"><strong>3️⃣ Say <code>"ciao"</code> to register the project on the left</strong><br/><span style="color: #5f6368;">Send a quick <code>ciao</code> so <code>rails8-app-on-gcp</code> appears in the left sidebar, then click <code>⋮</code> &rarr; <strong>Project Settings</strong>.</span></p>
<img src="images/agy-step3-project-settings.png" style="max-height: 150px; width: 100%; object-fit: contain;" alt="Step 3: Say ciao and open Project Settings" />
</div>
<div class="col-half" style="justify-content: flex-start; padding: 10px 12px;">
<p style="font-size: 0.78em; margin: 0;"><strong>4️⃣ Switch Security Preset to <code>Turbo mode</code></strong><br/><span style="color: #5f6368;">Under <strong>Agent Settings &rarr; Security Preset</strong> (right 👉), choose <strong>Turbo mode</strong> so Antigravity runs commands without nagging!</span></p>
</div>
<div class="disclaimer-box" style="margin-top: 0; font-size: 0.72em;">
🚨 <strong>TURBO MODE DISCLAIMER:</strong> Only enable Turbo mode for code that can be <strong>100% edited and managed by an agent</strong> in a workshop, codelab, or test environment! <strong>Never outsource your judgment to an agent — DO NOT DO THIS IN PROD!</strong>
</div>
</div>
<div style="flex: 1; text-align: center;">
<img src="images/agy-step4-turbo-mode.png" style="max-height: 545px; width: 100%; object-fit: contain; border-radius: 8px; border: 1px solid #dadce0; box-shadow: 0 6px 18px rgba(0,0,0,0.15);" alt="Step 4: Enable Turbo Mode in Security Preset" />
</div>
</div>

---

## Step 5: Prompt 2 — Start the Guided Workshop Journey 🎯

<div class="slide5-container">
<div class="slide5-col-left">

Inside your **`[turbo] rails8-app-on-gcp`** project, paste the **Workshop Mission Prompt**:

<div class="prompt-box" style="font-size: 0.74em;">
I am attending the Rails 8 on Google Cloud workshop. Please follow the official Google Codelab at: https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud#0 and guide me step-by-step through it! Read instructions at https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/landing-page/README.md
</div>

<button class="btn-copy" onclick="navigator.clipboard.writeText('I am attending the Rails 8 on Google Cloud workshop. Please follow the official Google Codelab at: https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud#0 and guide me step-by-step through it! Read instructions at https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/landing-page/README.md'); this.innerText='✅ Copied!'; setTimeout(() => this.innerText='📋 Copy Prompt 2 (Start Workshop)', 2000)">📋 Copy Prompt 2 (Start Workshop)</button>

<p style="font-size: 0.74em; color: #5f6368; margin-top: 8px;">
📖 Antigravity will read <code>workshop/landing-page/README.md</code>, load the repository tutor skills, and run <code>just workshop-test</code>!
</p>

</div>
<div class="slide5-col-right" style="flex: 0 0 600px;">

![Antigravity Prompt](images/antigravity-prompt-screenshot.png)

</div>
</div>

---

## Step 6 (Step 2.5): Claim GCP Credits on Codelab Page 2 💳

<div style="display: flex; gap: 28px; align-items: center; margin-top: 10px;">
<div style="flex: 1;">
<p style="margin: 0 0 10px 0; font-size: 0.94em;">Go to <strong>Page 2 (<code>#1</code>)</strong> of the Official Google Codelab to claim your free GCP credits:</p>
<a href="https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud?hl=it#1" target="_blank" rel="noopener noreferrer" title="Codelab in Italiano (#1)" style="position: absolute; top: 12px; right: 16px; font-size: 0.7em; text-decoration: none; opacity: 0.82;">🇮🇹</a>
<div style="margin: 10px 0 16px 0;">
<a href="https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud#1" target="_blank" rel="noopener noreferrer" style="display: inline-block; background-color: #1e8e3e; color: white; padding: 10px 22px; border-radius: 6px; text-decoration: none; font-weight: bold; font-size: 0.92em;">
🎟️ Open Codelab Page 2 (Credits)
</a>
</div>
<ul style="font-size: 0.88em; margin: 0; line-height: 1.45;">
<li>🌐 Open with <strong>Google Chrome</strong> and make sure you are logged into your personal <code>@gmail.com</code>.</li>
<li>🟢 <strong>Check: Do you see a GREEN button</strong> to claim credits? Let us know in the chat/comments!</li>
<li>⚠️ Early workshop steps run 100% on <code>localhost</code> while your billing activates.</li>
</ul>
</div>
<div style="text-align: center; background: white; padding: 14px; border-radius: 10px; border: 1px solid #dadce0; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
<img src="images/codelab-qr.png" style="width: 245px; height: 245px; border-radius: 8px; display: block;" alt="Scan QR Code to open Codelab" />
<p style="font-size: 0.7em; color: #5f6368; margin: 6px 0 0 0; font-weight: bold;">📱 Scan to open Codelab (#1)</p>
</div>
</div>

<div style="border: 1px solid #f9ab00; background-color: #fef7e0; border-radius: 6px; padding: 10px 14px; margin-top: 16px; font-size: 0.78em; line-height: 1.35;">
<strong>⚡ Out of Antigravity AI quota?</strong> Switch model pool under the prompt box to <strong>Claude / GPT-OSS</strong> or pick a <strong>Gemini Flash</strong> model (lighter on rate limits).
</div>

---

## Step 7: Prompt 3 — Create Your GCP Project (Post-Coupon) ☁️

After you have claimed your GCP coupon on Page 2, paste **Prompt 3** into Antigravity:

<div class="prompt-box" style="font-size: 0.9em; padding: 18px 22px; margin: 12px 0;">
I have claimed a GCP coupon. Create a project under my gmail, name it something like "workshop-rails8-YYYYMMDD" and add some random characters if needed.
</div>

<button class="btn-copy" style="font-size: 0.86em; padding: 10px 20px;" onclick="navigator.clipboard.writeText('I have claimed a GCP coupon. Create a project under my gmail, name it something like &quot;workshop-rails8-YYYYMMDD&quot; and add some random characters if needed.'); this.innerText='✅ Copied!'; setTimeout(() => this.innerText='📋 Copy Prompt 3 (Create GCP Project)', 2000)">📋 Copy Prompt 3 (Create GCP Project)</button>

<div class="highlight" style="margin-top: 18px; font-size: 0.88em; padding: 12px 18px;">
<p>🚀 <strong>What happens next:</strong> Antigravity creates your timestamped project (e.g. <code>workshop-rails8-20261007-x9a2</code>), links your trial billing account, updates <code>.env</code>, and verifies everything with <code>just workshop-test</code>!</p>
</div>

---

## Canonical Architecture Blueprint 🏛️

<div style="text-align: center; margin: 4px 0;">
<img src="images/arch_diagram.png" style="max-height: 505px; border-radius: 8px; box-shadow: 0 4px 16px rgba(0,0,0,0.15); border: 1px solid #dadce0;" alt="Rails 8 on GCP Architecture Diagram" />
</div>

<p style="font-size: 0.76em; color: #5f6368; text-align: center; margin: 4px 0 0 0;">
☁️ <strong>Full Production Reference Architecture:</strong> Cloud Run multi-container pod &middot; Cloud SQL PostgreSQL &middot; Private GCS &middot; Secret Manager &middot; Vertex AI
</p>

---

# Thank You! 🎉
### Let's Build with Google Antigravity 2.0 & Rails 8 🚀

<div style="display: flex; gap: 28px; align-items: center; margin-top: 10px;">
<div style="flex: 0 0 450px; text-align: center;">
<img src="images/slide1-style3-flat-vector.png" style="max-height: 410px; width: 100%; object-fit: contain; border-radius: 10px; box-shadow: 0 4px 16px rgba(0,0,0,0.15);" alt="Rails 8 on GCP" />
</div>
<div style="flex: 1; font-size: 0.84em;">
<div style="display: flex; flex-direction: column; gap: 10px; margin-bottom: 12px;">
<div style="display: flex; align-items: center; gap: 10px;">
<img src="images/riccardo-carlesso.webp" style="width: 44px; height: 44px; border-radius: 50%; object-fit: cover; border: 2px solid #1a73e8; box-shadow: 0 1px 4px rgba(0,0,0,0.15);" alt="Riccardo" />
<span>🦖 <strong>Riccardo:</strong> <a href="https://linkedin.com/in/riccardocarlesso" target="_blank" rel="noopener noreferrer">linkedin.com/in/riccardocarlesso</a></span>
</div>
<div style="display: flex; align-items: center; gap: 10px;">
<img src="images/emiliano-della-casa.png" style="width: 44px; height: 44px; border-radius: 50%; object-fit: cover; border: 2px solid #188038; box-shadow: 0 1px 4px rgba(0,0,0,0.15);" alt="Emiliano" />
<span>🏎️ <strong>Emiliano:</strong> <a href="https://www.linkedin.com/in/emilianodellacasa" target="_blank" rel="noopener noreferrer">linkedin.com/in/emilianodellacasa</a></span>
</div>
</div>
<p style="margin: 0 0 12px 0;">
👉 Official Codelab: <a href="https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud#0" target="_blank" rel="noopener noreferrer"><code>codelabs.developers.google.com/codelabs/rails8-on-google-cloud</code></a>
</p>

<div style="background-color: #f1f3f4; border: 1px solid #dadce0; border-radius: 6px; padding: 10px 14px; margin-top: 8px; font-size: 0.92em;">
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
<span style="font-weight: bold; color: #1a73e8; font-size: 0.9em;">🎵 Workshop Anthem</span>
<span style="font-size: 0.75em; color: #5f6368;">Lyria 3 Pro &middot; Vertex AI</span>
</div>
<audio controls preload="none" style="width: 100%; height: 28px; margin: 2px 0;">
<source src="https://raw.githubusercontent.com/palladius/rails8-app-on-gcp/artifacts/issue-44/assets/lyria-3-pro-preview.mp3" type="audio/mpeg">
Your browser does not support audio playback.
</audio>
<div style="display: flex; gap: 12px; font-size: 0.78em; margin-top: 3px;">
<span>⚡ <a href="https://raw.githubusercontent.com/palladius/rails8-app-on-gcp/artifacts/issue-44/assets/lyria-3-clip-preview.mp3" target="_blank" rel="noopener noreferrer">30s Clip</a></span>
<span>🎸 <a href="https://raw.githubusercontent.com/palladius/rails8-app-on-gcp/artifacts/issue-44/assets/lyria-3-pro-preview.mp3" target="_blank" rel="noopener noreferrer">Full 3m Song (3.4MB)</a></span>
</div>
</div>
</div>
</div>
