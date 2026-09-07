# 🤖 AGENTS.md — Directives & Blueprint for AI Coding Assistants

> This file contains the canonical project directives for AI coding agents (**Gemini**, **Claude Code**, and **Antigravity**).
> `GEMINI.md` is a symlink pointing directly to this file.
>

## File change

Note: This MD file **MUST** to adhere to `docs/CONSTITUTION.md` at all times. Make sure to ensure this before committing a change.

---

## 🎯 Dual North Stars

This repository serves **TWO EQUALLY CRITICAL GOALS**:

### 1. The Canonical "Rails 8 on Google Cloud" Blueprint (`main`)
- `main` is the comprehensive, production-grade reference architecture for modern Rails 8 on GCP.
- Includes all enterprise/cloud-native capabilities: Cloud SQL PostgreSQL with connection pooling, private Google Cloud Storage with IAM Credential blob signing, Secret Manager runtime injection, Cloud Run multi-container sidecars (`web` + `worker` Solid Queue + `cloudsql-proxy`), automated CI/CD via Cloud Build, and asynchronous AI jobs via Gemini / Imagen.
- `main` represents the fully assembled, editable end-state. Workshop steps are branches/checkpoints leading up to this blueprint.

### 2. The Universal Developer Workshop (Google Cloud & Antigravity for Everyone)
- **The Reality:** While premiering at a Ruby conference (Oct 2), **~90% of future workshop attendees will have zero Ruby background**. They are here to learn Google Cloud, serverless architecture, secure IAM practices, and AI pair programming with **Google Antigravity**.
- **Pedagogical Rule:** Never let Ruby syntax or Rails minutiae become a stumbling block. Keep application commands intuitive (`bin/dev`, `docker compose up`, `bin/rails db:...`), and use Antigravity / Gemini / Claude as the student's personal pair programmer to explain concepts, generate diagrams, and demystify the stack.
- **Focus:** Cloud-native architecture, eliminating security anti-patterns (e.g., no public `0.0.0.0/0`, no world-readable buckets), container sidecars on Cloud Run, and real-world GenAI background pipelines.

### 3. Environmental Telemetry & UI Storytelling (Visual Pedagogical Clues)
- **The Core Idea:** Students should instantly see where their application is running and what persistence/security tier is active via in-app UI badges and story-aligned seeded blog posts.
- **Dynamic Environment Detection:**
  - 🟡 **`[EPHEMERAL DB / STORAGE]` Badge:** Active when connected to local SQLite, local Docker Postgres (`localhost`/`db`), or local disk storage.
  - 🟢 **`[CLOUD PERSISTENT]` Badge:** Active when connected to managed Google Cloud SQL (via Cloud SQL Auth Proxy mTLS) and private Google Cloud Storage (`iam: true`).
- **Narrative-Driven Seeded Posts:**
  - Seeded posts evolve with the workshop narrative (e.g. *"[EPHEMERAL] ⚠️ Benvenuto! Sei su un DB locale effimero"* in Step 1 $\to$ *"[CLOUD SQL PERSISTENT] 🐘 Connesso a Google Cloud SQL"* in Step 3 $\to$ *"[AI ACTIVE] 🍌 Nano Banana / Imagen 3 Generatore di Copertine"* in Step 7).
  - This provides instant, tangible visual feedback when students graduate from suboptimal $\to$ cloud-native reference architecture.

---

## 👥 Key Personas

- **Riccardo:** Supreme Leader and pun-master 🦖
- **Emiliano:** Al Mudnais cal'scorda i symlink 🍝🏎️

---

## 🏛️ Project Scope & Collaboration

Riccardo and Emiliano collaborate on this project, which is bifidus (two-fold):
1. **Code Repo:** A Rails 8 app under `blog/`. An ambitious "Rails 8 blueprint, compatible with GCP", with all the I's dotted.
2. **Workshop:** Takes a student by the hand to reach awesomeness under `workshop/`. The flow: download the repo, use AI pair programming locally, deploy to GCP, and configure advanced capabilities like GCS and Cloud SQL.
3. **Branding:** Colorful, fun Google DevRel branding!
4. **Incremental Workshop:** While working on the app, incrementally build the multipage workshop under `workshop/`. Document design decisions as we go (e.g. why Docker Compose is structured this way) so no context is lost.

---

## ☁️ GCP & Architectural Decisions

1. **ActiveStorage + GCS:** Properly configured and tested with non-public objects and IAM Credential blob signing (`iam: true`).
2. **Docker Compose in Cloud Run:** Demonstrate `docker-compose` compatibility. Rubyists often prefer simplicity (Kamal, SQLite, baremetal); we meet them where they are and make GCP feel just as intuitive.
3. **DB Queues:** Skip external Kafka/PubSub overhead for application queues in favor of Rails 8 Solid Queue backed by the database.
4. **Terraform with Fabric FAST:** Use Fabric FAST for GCP Terraform. See `iac/README.md` and `iac/AGENTS.md` for specific infrastructure dispositions.

---

## 📁 Folder Structure

- App is under `blog/`
- Workshop is under `workshop/`. (See `workshop/AGENTS.md`)
- GCP setup is under `iac/`. (Cloud Build YAMLs, Terraform configurations, setup scripts)
- Do not use EXTERNAL symlinks; copy apps self-contained (avoiding committed `.env` secrets). Internal repository symlinks (like `GEMINI.md -> AGENTS.md`) are supported.

---

## 🔗 Dependencies & Build Artifact Flow

> ⚠️ **CRITICAL DIRECTIVE FOR AGENTS:** **NEVER manually edit generated HTML, JSON, or derived markdown files!** They are ephemeral build products compiled from master Markdown files. Any direct edit to HTML will be wiped out on the next build/CI run!

### 🗺️ File Dependency Map: Source of Truth $\to$ Produced Artifacts

* **`workshop/CODELAB.md` (SOURCE OF TRUTH)**
  $\to$ `ruby split_codelab.rb` $\to$ produces `workshop/render-app2/pages/*.md` & `pages.json` *(PRODUCED — DO NOT EDIT)*
  $\to$ `ruby build_ghpages.rb` $\to$ produces `workshop/build/index.html` *(PRODUCED — DO NOT EDIT)*

* **`workshop/UNTOUCHABLE-CONSTITUTION.md` (SOURCE OF TRUTH)**
  $\to$ `ruby build_ghpages.rb` $\to$ produces `workshop/build/constitution.html` *(PRODUCED — DO NOT EDIT)*

* **`workshop/SKELETON.md` (SOURCE OF TRUTH)**
  $\to$ `ruby build_ghpages.rb` $\to$ produces `workshop/build/skeleton.html` *(PRODUCED — DO NOT EDIT)*

* **`workshop/assets/*.jpg` (SOURCE OF TRUTH)**
  $\to$ copied to `blog/app/assets/images/` and `workshop/build/assets/` *(PRODUCED)*

* **`workshop/build/` + `workshop/render-app2/`**
  $\to$ `.github/workflows/deploy-pages.yml` (CI) $\to$ compiles and deploys `dist/` directly to GitHub Pages *(PRODUCED ON CI)*

* **`VERSION` (SOURCE OF TRUTH)**
  $\to$ referenced by `CHANGELOG.md`, footer UI, and release scripts.

---

## 🛠️ AI Development Guidelines

- **Pair Programming Assistants:** Gemini CLI, Claude Code, and Antigravity. Ensure the Conductor extension/skill is available: https://github.com/gemini-cli-extensions/conductor
- **Strict Semantic Versioning:** Ensure proper versioning in `VERSION` and `CHANGELOG.md` aligning with releases (e.g. useful for workshop errata).
- **Footer UI:** Surface app version in the footer alongside a link to GitHub code.
- **TDD:** Start with a failing test, prove it fails first, and iterate until green.
- **Verification Gates:** Ensure all tests pass. Never commit unless `just test` passes.

---

## 📦 Related Repositories

This is the flagship of 3 repos for the Rails 8 on GCP workshop:
- 🟢 **rails8-app-on-gcp** (THIS ONE) — Canonical app + GCP plumbing
- 🟡 **rails8-turbo-chat** (THE PAST) — Original chat app, battle-tested GCP configs
- 🔵 **rails8-turbo-chat-2026** (GCP INSPIRATION) — Emiliano's clean GCP-native fork
- In local dev setups, these are typically located under `~/git/<REPONAME>`.
