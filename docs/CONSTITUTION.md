# 📜 The Project Constitution

<!--
Current version: 1.3.0
Ratified by: Riccardo 🦖, Emiliano 🏎️, Antigravity AI 🤖
-->

This is the **immutable meta-constitution** of the repository.
`AGENTS.md` (and its symlink `GEMINI.md`), `workshop/UNTOUCHABLE-CONSTITUTION.md`, and all contributor workflows **MUST** adhere to these principles at all times.

Any modification to this constitution requires a **2/3 supermajority agreement** among the three maintainer personas:
1. **Riccardo** (Supreme Leader & Author 🦖)
2. **Emiliano** (Cloud & DevOps Architect 🏎️)
3. **AI** (Antigravity / Gemini Pair Programmer 🤖)

All proposed constitutional changes must be documented in a Pull Request referencing an issue where at least two maintainers have explicitly approved.

---

## 🏛️ Core Principles

### 0. Language Directive: English First
All application UI, code, comments, documentation, logs, tooltips, and workshop curriculum **MUST be written in ENGLISH**. Secondary audience is Italian, so Italian translations and cameo flavor are welcome, but English remains the universal source of truth.

### 1. The Modern Secure Monolith: Rails 8 Reference Blueprint on GCP
The repository serves as the definitive, production-grade reference architecture for running a modern, unified Ruby on Rails 8 monolith securely on Google Cloud Platform. Rather than fragmenting into premature microservices, we demonstrate how GCP elevates the classic monolith into an enterprise cloud-native deployment:

* **The Persona Contract:** When evaluating application code decisions, always test against this persona: **A seasoned Rails expert who is a newcomer to Google Cloud Platform**. What do they expect to find in an official canonical Google Cloud blueprint? Does this code represent idiomatic, production-grade Rails and GCP best practices, or unnecessary complexity?
* **The 4 Modern Monolith Pillars:**
  1. **Docker Compose Native on Cloud Run:** Full multi-container sidecar orchestration (`web` + `worker` Solid Queue + `cloudsql-proxy`) defined declaratively via Docker Compose (`compose.prod.yaml`) and deployed serverlessly without Kubernetes overhead.
  2. **Private ActiveStorage on GCS:** Non-public Google Cloud Storage bucket (`allUsers` strictly forbidden) with zero static service account keys in the app, using IAM Credentials API on-the-fly blob signing (`iam: true`).
  3. **Managed Cloud SQL via Localhost Proxy:** Production database persistence backed by Cloud SQL PostgreSQL, reaching the database over standard TCP `127.0.0.1:5432` through the official Auth Proxy sidecar with zero public IP exposure (`0.0.0.0/0` strictly prohibited).
  4. **Zero-Trust Runtime Secret Manager Injection:** Absolute elimination of committed secrets or long-lived plaintext credentials in environment variables; sensitive keys (`rails-master-key`, `rails-db-password`) are mounted directly at runtime via Google Cloud Secret Manager.

### 2. Workshop Presence & Future Migration Path
A companion step-by-step workshop **MUST** be maintained alongside the application. It currently resides under `workshop/`, with a recognized migration path toward a dedicated public Google repository in the future.

### 3. Step Progression: Zero-Branch Time-Machine & Hierarchical Git Namespaces
The workshop canonical progression uses **Zero-Branch Time-Machine overlays** (`workshop/time-machine/`), allowing students to rewind or advance the local configuration (`just workshop-rewind <N>`, `just workshop-restore-gold`) while staying comfortably on `main`.
When dedicated Git branches are published or used as milestone checkpoints, they **MUST** adhere to deterministic directory-style slashes:
`workshop/step-<N>-<slug>` (e.g., `workshop/step-0-setup`, `workshop/step-1-local-baseline`, `workshop/step-2-cloud-storage`).
> **Best Practice Note on Slashes (`/`):** Using slashes creates a clean hierarchical namespace under `refs/heads/workshop/`. Git clients, GitHub, and GitLab automatically group these branches into a collapsible tree view, preventing workshop steps from cluttering the root branch list.

### 4. `main` Converges with the Workshop End-State
Because the workshop guides learners through incremental code evolution, the `main` branch represents the fully assembled, production-ready final step (Step 8: Gold Standard). On `main`, managed Google Cloud SQL, private GCS with IAM signing, Secret Manager, Cloud Run sidecars, and background AI jobs are fully configured.

### 5. Environmental Telemetry & UI Storytelling
To maximize learning clarity, the application UI must provide instant, tangible visual cues about its running environment:
- **Dynamic Badges:** Explicitly distinguish ephemeral states (local SQLite, local Postgres container, local disk storage) from cloud-persistent states (Cloud SQL mTLS proxy, private GCS).
- **Narrative Content:** Seeded records must clearly identify their origin (e.g., *"written by db:seed"*).
- **Asset Provenance:** Placeholder images and media must visually communicate their storage tier (e.g., watermark/label indicating *"local image"* vs *"GCS private blob"*).

### 6. Localhost Invariant & Fast Diagnostic Tests (< 5s)
- **Localhost Invariant:** The application and workshop baseline must run on `localhost` at **ANY GIVEN TIME** without requiring live cloud credentials or an active internet connection.
- **Fast Diagnostic Tests:** Automated tests must execute with strict timeouts (**< 5 seconds**) and emit clear, actionable diagnostic messages if backing services (e.g., database, GCS, Cloud SQL Proxy) are unreachable or missing configuration. Learners and AI pair programmers must always be able to determine what is currently functional versus what requires configuration.

### 7. Ruby Version Pin: 3.4.5
The project is frozen to **Ruby 3.4.5**. This version **MUST** be consistent across all artifacts:
- `blog/.ruby-version`
- `blog/Dockerfile` (`ARG RUBY_VERSION`)
- `blog/config/deploy.yml`
- Any CI/CD workflow referencing Ruby

> **Rationale (FL006):** Ruby 4.0 introduced a stricter `URI::Generic` parser (RFC 3986 compliance) that breaks PostgreSQL connection strings using Unix socket paths with colons (e.g., Cloud SQL Auth Proxy `?host=/cloudsql/project:region:instance`). This mismatch between `.ruby-version` (3.4.5) and `Dockerfile` (4.0.5) caused production failures on Cloud Run. Decision ratified by Riccardo 🦖 and Emiliano 🏎️ on 2026-09-11.

### 8. Hierarchical Document Authority
`docs/CONSTITUTION.md` is the supreme governing document of this repository. In case of any conflict:
1. `docs/CONSTITUTION.md` (Supreme Meta-Constitution)
2. `AGENTS.md` / `GEMINI.md` (Agent Operational Directives)
3. `workshop/SKELETON.md` & `workshop/CODELAB.md` (Workshop Curriculum Specification & Step Contracts)
4. Derived artifacts, scripts, and documentation

### 9. Single Canonical Path: No "Forking Roads" (Mode A vs Mode B) in Core Progression
Never present the learner with a bifurcated choice between two development modes (e.g. "Choose Mode A or Mode B") during the core build-up of the application.
- **The Proctor Invariant:** If learners diverge into separate tracks (such as host-native vs Docker Compose), workshop proctors and teaching assistants cannot effectively diagnose or unblock students without first asking: *"In Step 2, did you pick A or B?"*
- **The Core Rule:** Choose the single highest-value canonical path (e.g. Docker Compose with Mailpit and Adminer) that guarantees reproducibility and identical mental models across all attendees.
- **The Capstone Exception:** Divergence and free-form creative choices are welcomed **only in the final capstone step**, where students can pick an optional challenge or feature of their choice *after* the canonical codelab architecture is fully built and deployed.

### 10. Multi-Container Production Deploy via Docker Compose (`compose.prod.yaml`)
The canonical production deployment on Google Cloud Run **MUST** be deployed using declarative multi-container specifications via `gcloud [alpha] run compose up compose.prod.yaml` (or its direct declarative equivalent):
- **Three-Container Invariant:** Production Cloud Run must run all three coordinated sidecars: `web` (Puma ingress on port 8080), `worker` (Solid Queue processor), and `cloudsql-proxy` (mTLS Auth Proxy).
- **No Deceptive Single-Container Shortcuts:** Deploying production via standard single-container CLI commands (`gcloud run deploy --source .`) while teaching a 3-container architecture is strictly forbidden. The learner's live Cloud Run Console "Containers" tab must genuinely display the 3 distinct sidecar containers.

