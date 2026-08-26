# 🧭 Project GEMINI & AGENTS Directives

## 🎯 Dual North Stars

This repository serves **TWO EQUALLY CRITICAL GOALS**:

### 1. The Canonical "Rails 8 on Google Cloud" Blueprint (`main`)
- `main` is the comprehensive, production-grade reference architecture for modern Rails 8 on GCP.
- Includes all enterprise/cloud-native capabilities: Cloud SQL PostgreSQL with connection pooling, private Google Cloud Storage with IAM Credential blob signing, Secret Manager runtime injection, Cloud Run multi-container sidecars (`web` + `worker` Solid Queue + `cloudsql-proxy`), automated CI/CD via Cloud Build, and asynchronous AI jobs via Gemini / Imagen.
- `main` represents the fully assembled, editable end-state. Workshop steps are branches/checkpoints leading up to this blueprint.

### 2. The Universal Developer Workshop (Google Cloud & Antigravity for Everyone)
- **The Reality:** While premiering at a Ruby conference (Oct 2), **~90% of future workshop attendees will have zero Ruby background**. They are here to learn Google Cloud, serverless architecture, secure IAM practices, and AI pair programming with **Google Antigravity**.
- **Pedagogical Rule:** Never let Ruby syntax or Rails minutiae become a stumbling block. Keep application commands intuitive (`bin/dev`, `docker compose up`, `bin/rails db:...`), and use Antigravity / Gemini as the student's personal pair programmer to explain concepts, generate diagrams, and demystify the stack.
- **Focus:** Cloud-native architecture, eliminating security anti-patterns (e.g., no public `0.0.0.0/0`, no world-readable buckets), container sidecars on Cloud Run, and real-world GenAI background pipelines.

### 3. Environmental Telemetry & UI Storytelling (Visual Pedagogical Clues)
- **The Core Idea:** Students should instantly see where their application is running and what persistence/security tier is active via in-app UI badges and story-aligned seeded blog posts.
- **Dynamic Environment Detection:**
  - 🟡 **`[EPHEMERAL DB / STORAGE]` Badge:** Active when connected to local SQLite, local Docker Postgres (`localhost`/`db`), or local disk storage.
  - 🟢 **`[CLOUD PERSISTENT]` Badge:** Active when connected to managed Google Cloud SQL (via Cloud SQL Auth Proxy mTLS) and private Google Cloud Storage (`iam: true`).
- **Narrative-Driven Seeded Posts:**
  - Seeded posts evolve with the workshop narrative (e.g. *"[EPHEMERAL] ⚠️ Benvenuto! Sei su un DB locale effimero"* in Step 1 $\to$ *"[CLOUD SQL PERSISTENT] 🐘 Connesso a Google Cloud SQL"* in Step 3 $\to$ *"[AI ACTIVE] 🍌 Nano Banana / Imagen 3 Generatore di Copertine"* in Step 7).
  - This provides instant, tangible visual feedback when students graduate from suboptimal $\to$ cloud-native reference architecture.

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

## 👥 Key Personas
- **Riccardo:** Supreme Leader and pun-master 🦖
- **Emiliano:** Al Mudnais cal'scorda i symlink 🍝🏎️
