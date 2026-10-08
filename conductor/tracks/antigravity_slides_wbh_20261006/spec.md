# Specification: Antigravity-Centric Workshop Kickoff Slides (EN/IT) & Wednesday Build Hour Deck

## 1. Overview
Following the premiere delivery of the *Rails 8 on Google Cloud* workshop at DevFest Modena (Sat Oct 3, 2026), we observed that onboarding attendees smoothly into **Google Antigravity 2.0** is the single most impactful part of the live kickoff. This track creates a dedicated, Antigravity-centric Marp presentation deck in both **English** (`slides/antigravity.en.md`)—for the **Wednesday Build Hour (WBH)** event on Oct 7, 2026—and **Italian** (`slides/antigravity.it.md`), leaving the original `slides/index.md` untouched.

## 2. Functional Requirements

### 2.1 Dual-Language Marp Slide Decks (`slides/antigravity.en.md` & `slides/antigravity.it.md`)
Create two standalone Marp slide decks sharing the Google Cloud / Gaia styling and interactive copy-to-clipboard buttons (`btn-copy`) from `slides/index.md`, structured around the 5-step Antigravity onboarding progression:
1. **Title Slide & Event Context:**
   - EN (`slides/antigravity.en.md`): Tailored for *Wednesday Build Hour (WBH) — From Zero to AI on Google Cloud with Google Antigravity 2.0 & Rails 8*, with QR code, speaker badges, and language switch link to the IT deck.
   - IT (`slides/antigravity.it.md`): Tailored for Italian workshop deliveries (DevFest Modena follow-up), with language switch link to the EN deck.
2. **Step 1 — Install Google Antigravity 2.0:**
   - Direct link (`https://antigravity.google/download`, `target="_blank" rel="noopener noreferrer"`), screenshot (`images/antigravity-download.png`), and explicit callout: *"💡 Windows users: use WSL for a smoother experience!"* (*"Nota: se avete Windows usate WSL, è più facile!"*).
3. **Step 2 — Sign In with Gmail:**
   - Instructions to open Antigravity 2.0 and sign in with a personal `@gmail.com` account (`images/antigravity-login.png`).
4. **Step 3 — Prompt 1: Clone the Repository into `Documents`:**
   - Interactive prompt box + `📋 Copy Prompt` button:
     - **EN:** `"Download https://github.com/palladius/rails8-app-on-gcp/ (via git clone) into my Documents folder and play a short sound when you are done."`
     - **IT:** `"Scaricami https://github.com/palladius/rails8-app-on-gcp/ (via git clone) dentro la cartella Documenti / Documents e suona un piccolo suono quando hai finito."`
5. **Step 4 (Step 1.5) — Open New Project in Cloned Folder & Enable TURBO Mode:**
   - Step-by-step instructions:
     1. Open Antigravity 2.0.
     2. Create/Open a **new project INSIDE** the newly cloned `Documents/rails8-app-on-gcp` folder.
     3. Set execution mode to **TURBO** so Antigravity executes commands autonomously without asking permission at every step.
   - Includes a dedicated visual container/placeholder (`images/antigravity-turbo-mode.png` / styled fallback box) ready to drop in Riccardo's custom screenshot(s).
6. **Step 5 — Prompt 2: Start the Official Google Codelab Guided Journey:**
   - Interactive prompt box + `📋 Copy Prompt` button:
     - **EN:** `"I am attending the Rails 8 on Google Cloud workshop. Please follow the official Google Codelab at: https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud#0 and guide me step-by-step through it! Read instructions at https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/landing-page/README.md"`
     - **IT:** `"Sto partecipando al workshop su Rails 8 su Google Cloud. Segui il Codelab ufficiale di Google all'indirizzo https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud?hl=it#0 e guidami passo dopo passo! Leggiti le istruzioni per agente qui: https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/landing-page/README.it.md"`
7. **Step 6 (Step 2.5) — Reclaim GCP Credits on Codelab Page 2:**
   - Direct link to Page 2 of the Codelab (`https://codelabs.developers.google.com/codelabs/rails8-on-google-cloud#1` in EN, `?hl=it#1` in IT), QR code (`images/codelab-qr.png`), and verification checklist:
     - Open in **Google Chrome** logged into your `@gmail.com` account.
     - Confirm you see the **GREEN button** to claim credits.
   - Includes the quota troubleshooting tip box (switching model pools to Claude/GPT-OSS or Flash if Antigravity free quota runs out).
8. **Step 7 — Prompt 3: Automated GCP Project Creation (Post-Coupon):**
   - Interactive prompt box + `📋 Copy Prompt` button:
     - **EN:** `"I have claimed a GCP coupon. Create a project under my gmail, name it something like 'workshop-rails8-YYYYMMDD' (or 'workshop-wbh-YYYYMMDD') and add some random characters if needed."`
     - **IT:** `"Ho reclamato un coupon di GCP. Crea un progetto sotto la mia gmail, chiamalo con un nome tipo 'workshop-modena-YYYYMMDD' e aggiungici altri caratteri random se non bastasse."`
9. **Architecture Blueprint & Thank You / Anthem Slides:**
   - Retain the canonical architecture overview (`images/arch_diagram.png`) and closing slide with speaker links and the Lyria 3 Pro Workshop Anthem player.

### 2.2 Build Pipeline, Justfile & Static Site Integration
- Update `justfile` (`build-slides` and a convenient recipe like `slides-agy` / `slides-antigravity`) so `slides/antigravity.en.md` and `slides/antigravity.it.md` compile cleanly into `slides/dist/antigravity.en.html` and `slides/dist/antigravity.it.html`.
- Update `workshop/visualizer/build_ghpages.rb` and `workshop/visualizer/server.rb` so the compiled Antigravity decks are copied into `workshop/build/slides/` and accessible both locally and on GitHub Pages (`/slides/antigravity.en.html` and `/slides/antigravity.it.html`).

### 2.3 Wednesday Build Hour Event Registration (`workshop/events/`)
- Create `workshop/events/20261007-wednesday-build-hour/README.md` documenting tomorrow's event (*"[WBH] How to bring your Rails 8 app to GCP with Riccardo Carlesso"*, Wed 7 Oct 2026, GDG Community Dev virtual URL, links to `antigravity.en.html` & `antigravity.it.html` slides and Codelab).
- Register the event in `workshop/events/README.md`.

## 3. Non-Functional Requirements
- **Zero Regression on Existing Slides:** `slides/index.md` and `slides/why-different.md` must remain untouched.
- **External Link Safety:** Every `<a href="http...">` tag in `slides/*.md` must include `target="_blank" rel="noopener noreferrer"` to pass `test/test_slides.rb` (preventing projector navigation away from the deck).
- **No Unrendered HTML in Marp:** All HTML blocks in `slides/antigravity.en.md` and `slides/antigravity.it.md` must avoid 4-space indentation so Marp never escapes them into `<code>` blocks.

## 4. Acceptance Criteria
- [ ] `slides/antigravity.en.md` and `slides/antigravity.it.md` exist, contain all 5+ steps and 3 copyable prompts from the Google Doc, and compile via `just build-slides` without errors.
- [ ] `ruby test/test_slides.rb` passes (and is extended to validate `antigravity.en.md` and `antigravity.it.md`).
- [ ] `workshop/events/20261007-wednesday-build-hour/README.md` is created and linked in `workshop/events/README.md`.
- [ ] `just test` passes, and `VERSION` and `CHANGELOG.md` are updated upon implementation.

## 5. Out of Scope
- Modifying application backend code under `blog/` or Terraform files under `iac/`.
- Modifying the original `slides/index.md` deck.
