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
    font-size: 23px;
    padding: 32px 52px;
    background-image: url('images/google-cloud-logo.svg');
    background-repeat: no-repeat;
    background-position: right 60px bottom 16px;
    background-size: 48px auto;
  }
  h1 {
    color: #1a73e8;
    font-size: 1.65em;
    margin: 0 0 0.25em 0;
  }
  h2 {
    color: #188038;
    font-size: 1.25em;
    margin: 0 0 0.25em 0;
  }
  h3 {
    font-size: 1.02em;
    margin: 0 0 0.25em 0;
    color: #3c4043;
  }
  p, ul, ol {
    margin: 0.22em 0;
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
    font-size: 0.85em;
    margin-top: 0.35em;
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
    line-height: 1.3;
  }
  .prompt-box {
    background-color: #202124;
    color: #e8eaed;
    padding: 12px 16px;
    border-radius: 8px;
    font-family: monospace;
    font-size: 0.78em;
    line-height: 1.38;
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
    align-items: flex-start;
    margin-top: 6px;
  }
  .col-half {
    flex: 1;
    background: white;
    padding: 10px;
    border-radius: 8px;
    border: 1px solid #dadce0;
    box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  }
  .col-half img {
    width: 100%;
    max-height: 210px;
    object-fit: contain;
    border-radius: 6px;
    border: 1px solid #e0e0e0;
    margin-top: 6px;
  }
  .slide5-container {
    display: flex;
    gap: 20px;
    align-items: flex-start;
    margin-top: 6px;
  }
  .slide5-col-left {
    flex: 1;
  }
  .slide5-col-right {
    flex: 0 0 430px;
    text-align: center;
  }
  .slide5-col-right img {
    width: 100%;
    border-radius: 8px;
    border: 1px solid #dadce0;
    box-shadow: 0 4px 14px rgba(0,0,0,0.15);
  }
  .btn-copy {
    margin-top: 6px;
    background-color: #1a73e8;
    color: white;
    border: none;
    padding: 6px 14px;
    border-radius: 6px;
    cursor: pointer;
    font-size: 0.72em;
    font-weight: bold;
    display: inline-flex;
    align-items: center;
    gap: 4px;
  }
---

# Da Zero al Cloud con Antigravity 2.0 🚀
### Workshop Hands-On: Rails 8 su Google Cloud & AI Pair Programming

<a href="antigravity.en.html" title="English Version" style="position: absolute; top: 12px; right: 16px; font-size: 0.7em; text-decoration: none; opacity: 0.82;">🇬🇧</a>
<div style="position: absolute; top: 36px; right: 42px; text-align: center; background: white; padding: 6px 8px 4px 8px; border-radius: 8px; border: 1px solid #dadce0; box-shadow: 0 2px 8px rgba(0,0,0,0.08);">
<img src="images/slides-qr.png" style="width: 78px; height: 78px; display: block;" alt="Slides QR Code" />
<span style="font-size: 0.42em; color: #5f6368; font-weight: bold; display: block; margin-top: 2px;">📱 Link Slide</span>
</div>

<div style="text-align: center; margin: 8px 0;">
<img src="images/slide1-style1-pixar.png" style="max-height: 315px; border-radius: 10px; box-shadow: 0 4px 16px rgba(0,0,0,0.15);" />
</div>

<p style="text-align: center; font-size: 0.78em; margin: 4px 0 0 0;">
<strong>Riccardo Carlesso</strong> 🦖 &amp; <strong>Emiliano Della Casa</strong> 🍝🏎️ &nbsp;&middot;&nbsp; <em>Google Cloud DevRel &amp; Open Source</em>
</p>

<div style="position: absolute; bottom: 14px; left: 35px; display: flex; align-items: center; gap: 8px;">
<img src="images/riccardo-carlesso.webp" style="width: 38px; height: 38px; border-radius: 50%; object-fit: cover; border: 2px solid #1a73e8; box-shadow: 0 2px 6px rgba(0,0,0,0.15);" alt="Riccardo" />
<img src="images/emiliano-della-casa.png" style="width: 38px; height: 38px; border-radius: 50%; object-fit: cover; border: 2px solid #188038; box-shadow: 0 2px 6px rgba(0,0,0,0.15);" alt="Emiliano" />
</div>

---

## Step 1: Scarica e Installa Google Antigravity 2.0 ⬇️

<div style="display: flex; gap: 16px; align-items: center; margin: 6px 0 8px 0;">
<a href="https://antigravity.google/download" target="_blank" rel="noopener noreferrer" style="display: inline-block; background-color: #1a73e8; color: white; padding: 6px 18px; border-radius: 6px; text-decoration: none; font-weight: bold; font-size: 0.85em;">
🚀 Scarica Antigravity 2.0
</a>
<span style="font-size: 0.78em; color: #3c4043;">🔗 <a href="https://antigravity.google/download" target="_blank" rel="noopener noreferrer" style="color: #1a73e8; text-decoration: none;">antigravity.google/download</a></span>
</div>

<div style="text-align: center; margin: 4px 0;">
<img src="images/antigravity-download.png" style="max-height: 245px; border-radius: 6px; box-shadow: 0 4px 12px rgba(0,0,0,0.12); border: 1px solid #dadce0;" alt="Download Antigravity 2.0" />
</div>

<div class="highlight">
<p>🪟 <strong>Nota per chi ha Windows:</strong> Usate <strong>WSL (Windows Subsystem for Linux)</strong> — è molto più facile per gestire Ruby, Docker e i comandi Linux!</p>
</div>

---

## Step 1.5: Nel frattempo, Apri il Codelab Ufficiale (Pagina 1 &rarr; `#0`) 📖

<div class="two-col" style="align-items: center; margin-top: 6px;">
<div style="flex: 0 0 43%; display: flex; flex-direction: column; gap: 8px;">
<div>
<a href="https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud?hl=it#0" target="_blank" rel="noopener noreferrer" style="display: inline-block; background-color: #1a73e8; color: white; padding: 7px 16px; border-radius: 6px; text-decoration: none; font-weight: bold; font-size: 0.82em;">
📖 Apri il Codelab Ufficiale (#0)
</a>
</div>
<ul style="font-size: 0.74em; margin: 0; padding-left: 18px;">
<li>⏳ <strong>Mentre Antigravity scarica:</strong> aprite il Codelab in <strong>Google Chrome</strong>!</li>
<li>🔢 <strong>Pagina 1 (<code>#0</code>):</strong> Introduzione &amp; Panoramica Architetturale.</li>
<li>💳 <strong>Pagina 2 (<code>#1</code>):</strong> Prerequisiti &amp; <strong>Crediti GCP Gratuiti</strong> (ci andremo allo Step 6!).</li>
</ul>
<div style="display: flex; align-items: center; gap: 10px; margin-top: 2px;">
<img src="images/codelab-qr.png" style="width: 105px; height: 105px; border-radius: 6px; border: 1px solid #dadce0; box-shadow: 0 2px 8px rgba(0,0,0,0.1);" alt="Codelab QR Code" />
<span style="font-size: 0.65em; color: #5f6368;">📱 <strong>Scansiona il QR per il Codelab</strong><br/><a href="https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud?hl=it#0" target="_blank" rel="noopener noreferrer" style="color: #1a73e8;">codelabs.../rails8-on-google-cloud#0</a></span>
</div>
</div>
<div style="flex: 1; text-align: center;">
<img src="images/codelab-page1-intro.png" style="max-height: 315px; max-width: 100%; border-radius: 8px; border: 1px solid #dadce0; box-shadow: 0 4px 14px rgba(0,0,0,0.14);" alt="Google Codelab Pagina 1 (#0) Introduzione" />
</div>
</div>

---

## Step 2: Fai Login con il tuo Account Gmail 🔐

1. Apri **Google Antigravity 2.0** &nbsp;&middot;&nbsp; 2. Clicca **Sign in with Google** &nbsp;&middot;&nbsp; 3. Autorizza l'agente.

<div style="text-align: center; margin: 10px 0;">
<img src="images/antigravity-login.png" style="max-height: 300px; border-radius: 8px; box-shadow: 0 4px 16px rgba(0,0,0,0.25); border: 1px solid #3c4043;" alt="Sign in with Google" />
</div>

<p style="font-size: 0.82em; color: #3c4043; text-align: center; margin: 6px 0 0 0;">
💡 Effettua il login con il tuo account <code>@gmail.com</code> personale (lo stesso che userai per riscattare i crediti GCP).
</p>

---

## Step 3: Prompt 1 — Scarica il Repo in `Documents` 📥

Incolla questo **primo prompt** nella chat di Antigravity per clonare il repository in `Documenti` / `Documents`:

<div class="prompt-box">
Scaricami https://github.com/palladius/rails8-app-on-gcp/ (via git clone) dentro la cartella Documenti / Documents e suona un piccolo suono quando hai finito.
</div>

<button class="btn-copy" onclick="navigator.clipboard.writeText('Scaricami https://github.com/palladius/rails8-app-on-gcp/ (via git clone) dentro la cartella Documenti / Documents e suona un piccolo suono quando hai finito.'); this.innerText='✅ Copiato!'; setTimeout(() => this.innerText='📋 Copia Prompt 1 (Git Clone)', 2000)">📋 Copia Prompt 1 (Git Clone)</button>

<div class="highlight" style="margin-top: 14px;">
<p>🤖 <strong>Perché farlo via prompt?</strong> Antigravity verifica che <code>git</code> sia installato, clona <code>rails8-app-on-gcp</code> dentro <code>~/Documents/rails8-app-on-gcp</code> e riproduce un suono appena ha finito!</p>
</div>

---

## Step 4a (Step 1.5): Crea un Nuovo Progetto nella Cartella Clonata 📁

Appena finisce il clone, apri un **nuovo progetto DENTRO** quella cartella:

<div class="two-col">
<div class="col-half">
<p style="font-size: 0.82em; margin: 0;"><strong>1️⃣ Clicca <code>New Project</code> (Select a folder)</strong><br/><span style="color: #5f6368; font-size: 0.9em;">Nella barra di sinistra <strong>Projects</strong>, clicca l'icona cartella+ e scegli <strong>New Project</strong>.</span></p>
<img src="images/agy-step1-new-project.png" alt="Step 1: Clicca New Project in Antigravity" />
</div>
<div class="col-half">
<p style="font-size: 0.82em; margin: 0;"><strong>2️⃣ Seleziona <code>Documents/rails8-app-on-gcp</code></strong><br/><span style="color: #5f6368; font-size: 0.9em;">Vai in <strong>Home / Documents</strong> e seleziona la cartella appena clonata <code>rails8-app-on-gcp</code>.</span></p>
<img src="images/agy-step2-select-folder.png" alt="Step 2: Seleziona la cartella Documents/rails8-app-on-gcp" />
</div>
</div>

---

## Step 4b (Step 1.5): Scrivi `"ciao"` e Attiva la TURBO Mode ⚡

<div class="two-col">
<div class="col-half">
<p style="font-size: 0.78em; margin: 0;"><strong>3️⃣ Scrivi <code>"ciao"</code> per far apparire il progetto a sinistra</strong><br/><span style="color: #5f6368;">Invia <code>ciao</code> in chat per attivare la conversazione nella barra a sinistra, poi clicca <code>⋮</code> &rarr; <strong>Project Settings</strong>.</span></p>
<img src="images/agy-step3-project-settings.png" style="max-height: 155px;" alt="Step 3: Scrivi ciao e apri Project Settings" />
</div>
<div class="col-half">
<p style="font-size: 0.78em; margin: 0;"><strong>4️⃣ Imposta Security Preset su <code>Turbo mode</code></strong><br/><span style="color: #5f6368;">Sotto <strong>Agent Settings &rarr; Security Preset</strong>, seleziona <strong>Turbo mode</strong> così non fa domande a ogni comando!</span></p>
<img src="images/agy-step4-turbo-mode.png" style="max-height: 175px;" alt="Step 4: Attiva Turbo Mode in Security Preset" />
</div>
</div>

<div class="disclaimer-box">
🚨 <strong>DISCLAIMER TURBO MODE:</strong> Attivate questa modalità SOLO su codice che può essere <strong>modificato e gestito al 100% da un agente</strong> in un workshop, codelab o ambiente di test! <strong>Non delegate mai il vostro giudizio a un agente — NON FATELO MAI IN PROD!</strong>
</div>

---

## Step 5: Prompt 2 — Il Prompt del Workshop Vero e Proprio 🎯

<div class="slide5-container">
<div class="slide5-col-left">

Dentro il progetto **`[turbo] rails8-app-on-gcp`**, incolla il **Prompt del Workshop**:

<div class="prompt-box" style="font-size: 0.72em;">
Sto partecipando al workshop su Rails 8 su Google Cloud. Segui il Codelab ufficiale di Google all'indirizzo https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud#0 e guidami passo dopo passo! Leggiti le istruzioni per agente qui: https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/landing-page/README.it.md
</div>

<button class="btn-copy" onclick="navigator.clipboard.writeText('Sto partecipando al workshop su Rails 8 su Google Cloud. Segui il Codelab ufficiale di Google all\'indirizzo https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud#0 e guidami passo dopo passo! Leggiti le istruzioni per agente qui: https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/landing-page/README.it.md'); this.innerText='✅ Copiato!'; setTimeout(() => this.innerText='📋 Copia Prompt 2 (Avvia Workshop)', 2000)">📋 Copia Prompt 2 (Avvia Workshop)</button>

<p style="font-size: 0.74em; color: #5f6368; margin-top: 8px;">
📖 Antigravity leggerà <code>workshop/landing-page/README.it.md</code>, caricherà le skill del repository e lancerà <code>just workshop-test</code>!
</p>

</div>
<div class="slide5-col-right">

![Antigravity Prompt](images/antigravity-prompt-screenshot.png)

</div>
</div>

---

## Step 6 (Step 2.5): Reclama i Crediti GCP a Pagina 2 del Codelab 💳

<div style="display: flex; gap: 20px; align-items: flex-start; margin-top: 4px;">
<div style="flex: 1;">
<p style="margin: 0 0 6px 0;">Vai a <strong>Pagina 2</strong> del Codelab ufficiale per reclamare i crediti gratuiti Google Cloud:</p>
<a href="https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud#1" target="_blank" rel="noopener noreferrer" title="English Codelab (#1)" style="position: absolute; top: 12px; right: 16px; font-size: 0.7em; text-decoration: none; opacity: 0.82;">🇬🇧</a>
<div style="margin: 6px 0 10px 0;">
<a href="https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud?hl=it#1" target="_blank" rel="noopener noreferrer" style="display: inline-block; background-color: #1e8e3e; color: white; padding: 7px 16px; border-radius: 6px; text-decoration: none; font-weight: bold; font-size: 0.82em;">
🎟️ Apri Codelab Pagina 2 (Crediti IT)
</a>
</div>
<ul style="font-size: 0.8em; margin: 0;">
<li>🌐 Aprite con <strong>Google Chrome</strong> e assicuratevi di essere loggati con il vostro <code>@gmail.com</code>.</li>
<li>🟢 <strong>Mi confermate che vedete un bottone VERDE?</strong> Commentate / diteci se sì o no!</li>
<li>⚠️ I primi step girano al 100% su <code>localhost</code> mentre il billing si attiva.</li>
</ul>
</div>
<div style="text-align: center;">
<img src="images/codelab-qr.png" style="width: 150px; height: 150px; border-radius: 8px; border: 1px solid #dadce0; box-shadow: 0 4px 12px rgba(0,0,0,0.12);" alt="Scan QR Code to open Codelab" />
<p style="font-size: 0.64em; color: #5f6368; margin-top: 3px;">📱 Scansiona per aprire il Codelab</p>
</div>
</div>

<div style="border: 1px solid #f9ab00; background-color: #fef7e0; border-radius: 6px; padding: 7px 12px; margin-top: 8px; font-size: 0.7em; line-height: 1.3;">
<strong>⚡ Finiti i crediti gratuiti di Antigravity?</strong> Cambia modello sotto il box del prompt scegliendo <strong>Claude / GPT-OSS</strong> oppure un modello <strong>Gemini Flash</strong>.
</div>

---

## Step 7: Prompt 3 — Crea il Progetto GCP (Dopo il Coupon) ☁️

Dopo che avete reclamato il coupon GCP a Pagina 2, incollate il **Prompt 3** in Antigravity:

<div class="prompt-box">
Ho reclamato un coupon di GCP. Crea un progetto sotto la mia gmail, chiamalo con un nome tipo "workshop-modena-YYYYMMDD" e aggiungici altri caratteri random se non bastasse.
</div>

<button class="btn-copy" onclick="navigator.clipboard.writeText('Ho reclamato un coupon di GCP. Crea un progetto sotto la mia gmail, chiamalo con un nome tipo &quot;workshop-modena-YYYYMMDD&quot; e aggiungici altri caratteri random se non bastasse.'); this.innerText='✅ Copiato!'; setTimeout(() => this.innerText='📋 Copia Prompt 3 (Crea Progetto GCP)', 2000)">📋 Copia Prompt 3 (Crea Progetto GCP)</button>

<div class="highlight" style="margin-top: 12px;">
<p>🚀 <strong>Cosa succede ora:</strong> Antigravity crea il progetto (es. <code>workshop-modena-20261007-x9a2</code>), collega il billing account del coupon, aggiorna il file <code>.env</code> e verifica tutto con <code>just workshop-test</code>!</p>
</div>

---

## Architettura Canonica di Riferimento 🏛️

<div style="text-align: center; margin: 4px 0;">
<img src="images/arch_diagram.png" style="max-height: 320px; border-radius: 8px; box-shadow: 0 4px 16px rgba(0,0,0,0.15); border: 1px solid #dadce0;" alt="Rails 8 on GCP Architecture Diagram" />
</div>

<p style="font-size: 0.72em; color: #5f6368; text-align: center; margin: 4px 0 0 0;">
☁️ <strong>Full Production Reference Architecture:</strong> Cloud Run multi-container pod &middot; Cloud SQL PostgreSQL &middot; Private GCS &middot; Secret Manager &middot; Vertex AI
</p>

---

# Grazie! 🎉
### Costruiamo insieme con Google Antigravity 2.0 & Rails 8 🚀

<div style="display: flex; gap: 20px; align-items: center; margin-top: 4px;">
<div style="flex: 0 0 240px; text-align: center;">
<img src="images/slide1-style3-flat-vector.png" style="max-height: 220px; border-radius: 10px; box-shadow: 0 4px 16px rgba(0,0,0,0.15);" alt="Rails 8 on GCP" />
</div>
<div style="flex: 1; font-size: 0.78em;">
<div style="display: flex; flex-direction: column; gap: 6px; margin-bottom: 8px;">
<div style="display: flex; align-items: center; gap: 8px;">
<img src="images/riccardo-carlesso.webp" style="width: 28px; height: 28px; border-radius: 50%; object-fit: cover; border: 2px solid #1a73e8; box-shadow: 0 1px 4px rgba(0,0,0,0.15);" alt="Riccardo" />
<span>🦖 <strong>Riccardo:</strong> <a href="https://linkedin.com/in/riccardocarlesso" target="_blank" rel="noopener noreferrer">linkedin.com/in/riccardocarlesso</a></span>
</div>
<div style="display: flex; align-items: center; gap: 8px;">
<img src="images/emiliano-della-casa.png" style="width: 28px; height: 28px; border-radius: 50%; object-fit: cover; border: 2px solid #188038; box-shadow: 0 1px 4px rgba(0,0,0,0.15);" alt="Emiliano" />
<span>🏎️ <strong>Emiliano:</strong> <a href="https://www.linkedin.com/in/emilianodellacasa" target="_blank" rel="noopener noreferrer">linkedin.com/in/emilianodellacasa</a></span>
</div>
</div>
<p style="margin: 0 0 8px 0;">
👉 Codelab Ufficiale: <a href="https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud?hl=it#0" target="_blank" rel="noopener noreferrer"><code>codelabs.developers.google.com/codelabs/rails8-on-google-cloud?hl=it</code></a>
</p>

<div style="background-color: #f1f3f4; border: 1px solid #dadce0; border-radius: 6px; padding: 6px 10px; margin-top: 4px; font-size: 0.9em;">
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 3px;">
<span style="font-weight: bold; color: #1a73e8; font-size: 0.88em;">🎵 Workshop Anthem</span>
<span style="font-size: 0.75em; color: #5f6368;">Lyria 3 Pro &middot; Vertex AI</span>
</div>
<audio controls preload="none" style="width: 100%; height: 26px; margin: 2px 0;">
<source src="https://raw.githubusercontent.com/palladius/rails8-app-on-gcp/artifacts/issue-44/assets/lyria-3-pro-preview.mp3" type="audio/mpeg">
Your browser does not support audio playback.
</audio>
<div style="display: flex; gap: 12px; font-size: 0.78em; margin-top: 2px;">
<span>⚡ <a href="https://raw.githubusercontent.com/palladius/rails8-app-on-gcp/artifacts/issue-44/assets/lyria-3-clip-preview.mp3" target="_blank" rel="noopener noreferrer">Clip 30s</a></span>
<span>🎸 <a href="https://raw.githubusercontent.com/palladius/rails8-app-on-gcp/artifacts/issue-44/assets/lyria-3-pro-preview.mp3" target="_blank" rel="noopener noreferrer">Canzone Intera 3m (3.4MB)</a></span>
</div>
</div>
</div>
</div>
