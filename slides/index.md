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
  }
  h1 {
    color: #1a73e8;
  }
  h2 {
    color: #188038;
  }
  footer {
    font-size: 0.55em;
    color: #5f6368;
  }
  .highlight {
    background-color: #e8f0fe;
    border-left: 5px solid #1a73e8;
    padding: 12px 18px;
    border-radius: 4px;
  }
  .prompt-box {
    background-color: #202124;
    color: #e8eaed;
    padding: 16px 20px;
    border-radius: 8px;
    font-family: monospace;
    font-size: 0.85em;
    line-height: 1.5;
  }
  .badge {
    display: inline-block;
    padding: 4px 10px;
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

**Riccardo Carlesso** 🦖 & **Emiliano** 🍝🏎️
Google Cloud & Open Source

---

## 1. Download & Install Antigravity 📥

Google Antigravity is your agentic pair programming harness for this workshop.

- **Download:** Get the latest release for your OS:
  - 🍏 **macOS** (Universal `.dmg` / `.zip`)
  - 🐧 **Linux** (`.deb` / `.AppImage` / tarball)
  - 🪟 **Windows** (`.exe` installer)

<div class="highlight">

💡 **No Ruby experience needed!** 
Antigravity pairs with you to explain every concept, command, and cloud architecture decision.

</div>

---

## 2. Launch & Connect Your Account 🔐

1. Open **Google Antigravity** on your laptop.
2. Sign in with your **Google Account** (`@gmail.com` or corporate Google identity).
3. Authorize the pair programmer agent.

```
┌────────────────────────────────────────────────────────┐
│  🚀 Welcome to Google Antigravity                      │
│                                                        │
│  [ G  Sign in with Google ]                            │
│                                                        │
│  Connected: you@domain.com  🟢 Ready                   │
└────────────────────────────────────────────────────────┘
```

---

## 3. [Optional] Reclaim Cloud Credits 💳

If this is a live in-person or virtual workshop, redeem your Google Cloud credits:

- 🎟️ **Scan the Workshop QR Code** or follow the event voucher link.
- ☁️ Activate your sandbox GCP Project.
- 💵 Ensure your active billing/voucher covers Cloud Run, Cloud SQL, and Cloud Storage.

<div class="highlight">

⚠️ **Localhost First!** Everything in the initial workshop steps runs 100% locally on your machine with SQLite and Docker Compose before touching the cloud.

</div>

---

## 4. Launch Antigravity & Set The Mission 🎯

Open Antigravity and paste the following prompt in the chat:

<div class="prompt-box">
"I am attending the Rails 8 on Google Cloud workshop.<br/>
Please inspect:<br/>
https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/LANDING_PAGE.md<br/>
(or workshop/LANDING_PAGE.it.md if you prefer Italian)<br/>
and guide me step-by-step through the workshop!"
</div>

---

## 5. The Pedagogical Contract 🤝

> *"Teach me and help me understand step by step. Do NOT do everything for me!"*

- 🧑‍🏫 **Socratic Guidance:** Antigravity explains *why*, not just *what*.
- 🛠️ **`justfile` Central:** All workflows are orchestrated with simple recipes:
  - `just slides` — These slides (`http://localhost:8082`)
  - `just workshop-dev` — Workshop Codelab app (`http://localhost:8080`)
  - `just dev` — Local Rails 8 app (`http://localhost:3000`)
  - `just test` — Rapid automated test suite

**Let's build on Google Cloud! 🎉**
