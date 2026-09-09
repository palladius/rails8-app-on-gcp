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
    padding: 35px 55px;
    background-image: url('images/google-cloud-logo.svg');
    background-repeat: no-repeat;
    background-position: right 60px bottom 16px;
    background-size: 48px auto;
  }
  h1 {
    color: #1a73e8;
    font-size: 1.7em;
    margin: 0 0 0.3em 0;
  }
  h2 {
    color: #188038;
    font-size: 1.3em;
    margin: 0 0 0.3em 0;
  }
  h3 {
    font-size: 1.05em;
    margin: 0 0 0.3em 0;
    color: #3c4043;
  }
  p, ul, ol {
    margin: 0.25em 0;
    line-height: 1.35;
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
    font-size: 0.88em;
    margin-top: 0.4em;
  }
  .highlight p {
    margin: 0.2em 0;
  }
  .prompt-box {
    background-color: #202124;
    color: #e8eaed;
    padding: 12px 16px;
    border-radius: 8px;
    font-family: monospace;
    font-size: 0.8em;
    line-height: 1.4;
    margin: 0.4em 0;
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
---

# Rails 8 on Google Cloud 🚀
### Workshop Kickoff & Pair Programming with Google Antigravity

<div style="text-align: center; margin: 10px 0;">
  <img src="images/slide1-style1-pixar.png" style="max-height: 330px; border-radius: 10px; box-shadow: 0 4px 16px rgba(0,0,0,0.15);" />
</div>

<p style="text-align: center; font-size: 0.8em; margin: 6px 0 0 0;">
  <strong>Riccardo Carlesso</strong> 🦖 &amp; <strong>Emiliano</strong> 🍝🏎️ &nbsp;&middot;&nbsp; <em>Google Cloud &amp; Open Source</em>
</p>

<div style="position: absolute; bottom: 14px; left: 35px; display: flex; align-items: center; gap: 8px;">
  <img src="images/riccardo-carlesso.webp" style="width: 38px; height: 38px; border-radius: 50%; object-fit: cover; border: 2px solid #1a73e8; box-shadow: 0 2px 6px rgba(0,0,0,0.15);" alt="Riccardo" />
  <img src="images/emiliano-della-casa.png" style="width: 38px; height: 38px; border-radius: 50%; object-fit: cover; border: 2px solid #188038; box-shadow: 0 2px 6px rgba(0,0,0,0.15);" alt="Emiliano" />
</div>

---

## 1. Download Google Antigravity 2.0 📥

<div style="margin: 8px 0 12px 0;">
  <a href="https://antigravity.google/download" style="display: inline-block; background-color: #1a73e8; color: white; padding: 6px 16px; border-radius: 6px; text-decoration: none; font-weight: bold; font-size: 0.85em;">
    🚀 Download Antigravity 2.0 (antigravity.google/download)
  </a>
</div>

<div style="text-align: center; margin: 4px 0;">
  <img src="images/antigravity-download.png" style="max-height: 290px; border-radius: 6px; box-shadow: 0 4px 12px rgba(0,0,0,0.12); border: 1px solid #dadce0;" />
</div>

<p style="font-size: 0.8em; color: #5f6368; text-align: center; margin: 6px 0 0 0;">
  💡 <strong>Note:</strong> Not CLI, not IDE — <strong>Antigravity 2.0</strong> is all you need!
</p>

---

## 2. Launch & Connect Your Account 🔐

1. Open **Google Antigravity** &nbsp;&middot;&nbsp; 2. Click **Sign in with Google** &nbsp;&middot;&nbsp; 3. Authorize agent.

<div style="text-align: center; margin: 10px 0;">
  <img src="images/antigravity-login.png" style="max-height: 310px; border-radius: 8px; box-shadow: 0 4px 16px rgba(0,0,0,0.25); border: 1px solid #3c4043;" alt="Sign in with Google" />
</div>

<p style="font-size: 0.8em; color: #5f6368; text-align: center; margin: 4px 0 0 0;">
  💡 Sign in with your personal <code>@gmail.com</code> or workshop Google identity.
</p>

---

## 3. Reclaim Credits Now 💳

<div style="display: flex; gap: 24px; align-items: flex-start; margin-top: 8px;">
  <div style="flex: 1;">
    <p>Redeem your Google Cloud credits for today's workshop:</p>
    <div style="margin: 10px 0 14px 0;">
      <a href="https://me.developers.google.com/benefits/claim/test-workshop-rails8" style="display: inline-block; background-color: #1a73e8; color: white; padding: 8px 16px; border-radius: 6px; text-decoration: none; font-weight: bold; font-size: 0.85em;">
        🎟️ Claim GCP Credits
      </a>
    </div>
    <ul style="font-size: 0.85em;">
      <li>🔗 <strong>Link:</strong> <a href="https://me.developers.google.com/benefits/claim/test-workshop-rails8">me.developers.google.com/...</a></li>
      <li>☁️ Activate sandbox GCP Project & billing.</li>
      <li>💵 Covers Cloud Run, Cloud SQL & GCS.</li>
    </ul>
  </div>
  <div style="text-align: center;">
    <img src="images/reclaim-credits-qr.png" style="width: 190px; height: 190px; border-radius: 8px; border: 1px solid #dadce0; box-shadow: 0 4px 12px rgba(0,0,0,0.12);" alt="Scan QR Code to Claim Credits" />
    <p style="font-size: 0.7em; color: #5f6368; margin-top: 4px;">📱 Scan with phone camera</p>
  </div>
</div>

<div class="highlight" style="font-size: 0.8em; margin-top: 8px;">

⚠️ **Localhost First!** Initial steps run 100% locally on SQLite/Docker before touching the cloud.

</div>

---

## 4. Launch Antigravity & Set The Mission 🎯

Open Antigravity and paste the following prompt in the chat:

<div class="prompt-box">
"I am attending the Rails 8 on Google Cloud workshop.<br/>
Please inspect:<br/>
https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/landing-page/README.md<br/>
(or workshop/landing-page/README.it.md if you prefer Italian)<br/>
and guide me step-by-step through the workshop!"
</div>

---

# Thank You! 🎉
### Let's Build Rails 8 on Google Cloud 🚀

<div style="display: flex; gap: 20px; align-items: center; margin-top: 4px;">
<div style="flex: 0 0 240px; text-align: center;">
<img src="images/slide1-style3-flat-vector.png" style="max-height: 220px; border-radius: 10px; box-shadow: 0 4px 16px rgba(0,0,0,0.15);" />
</div>
<div style="flex: 1; font-size: 0.78em;">
<p style="margin: 0 0 6px 0;">
🦖 <strong>Riccardo:</strong> <a href="https://linkedin.com/in/riccardocarlesso">linkedin.com/in/riccardocarlesso</a> &nbsp;&middot;&nbsp; 
🏎️ <strong>Emiliano:</strong> <a href="https://www.linkedin.com/in/emilianodellacasa">linkedin.com/in/emilianodellacasa</a>
</p>
<p style="margin: 0 0 8px 0;">
👉 Start hacking at <a href="https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/landing-page/README.md"><code>workshop/landing-page/README.md</code></a>
</p>

<div style="background-color: #f1f3f4; border: 1px solid #dadce0; border-radius: 8px; padding: 8px 12px; margin-top: 6px;">
<p style="font-weight: bold; margin: 0 0 4px 0; color: #1a73e8; font-size: 0.95em;">
🎵 Workshop Anthem (Lyria 3 Pro on Vertex AI)
</p>
<p style="margin: 0 0 6px 0; font-size: 0.88em; color: #3c4043;">
▶️ <em>Check this great song:</em>
</p>
<audio controls preload="none" style="width: 100%; height: 32px; margin-bottom: 4px;">
<source src="https://raw.githubusercontent.com/palladius/rails8-app-on-gcp/artifacts/issue-44/assets/lyria-3-pro-preview.mp3" type="audio/mpeg">
Your browser does not support audio playback.
</audio>
<div style="display: flex; gap: 12px; font-size: 0.82em; margin-top: 4px;">
<span>⚡ <a href="https://raw.githubusercontent.com/palladius/rails8-app-on-gcp/artifacts/issue-44/assets/lyria-3-clip-preview.mp3">30s Short Clip</a></span>
<span>🎸 <a href="https://raw.githubusercontent.com/palladius/rails8-app-on-gcp/artifacts/issue-44/assets/lyria-3-pro-preview.mp3">Full 3m Song (3.4MB)</a></span>
</div>
</div>
</div>
</div>

<div style="position: absolute; bottom: 12px; left: 35px; display: flex; align-items: center; gap: 8px;">
  <img src="images/riccardo-carlesso.webp" style="width: 34px; height: 34px; border-radius: 50%; object-fit: cover; border: 2px solid #1a73e8; box-shadow: 0 2px 6px rgba(0,0,0,0.15);" alt="Riccardo" />
  <img src="images/emiliano-della-casa.png" style="width: 34px; height: 34px; border-radius: 50%; object-fit: cover; border: 2px solid #188038; box-shadow: 0 2px 6px rgba(0,0,0,0.15);" alt="Emiliano" />
</div>


