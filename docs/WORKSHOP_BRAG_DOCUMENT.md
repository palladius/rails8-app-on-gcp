# 🏆 Workshop BRAG Document: Deploying Modern Rails 8 on Google Cloud (From Zero to AI)

> **The Definitive Monolith-to-Serverless Reference Architecture & Autonomous Workshop Engineering Engine**  
> *Authors: Riccardo Carlesso & Emiliano Mancuso (with AI Partner Antigravity)*  
> *Repository:* [`palladius/rails8-app-on-gcp`](https://github.com/palladius/rails8-app-on-gcp)

---

## 🎯 Executive Summary: Why is this Workshop Revolutionary?

Most technical cloud workshops suffer from one of two fatal flaws:
1. **Dumbed-down "Hello World" toys**: Deploying a single stateless container with zero production realism (ephemeral SQLite in containers, insecure `0.0.0.0/0` firewall holes, world-readable storage buckets).
2. **Brittle, manual click-ops marathons**: Long, fragile instructions that silently rot the minute an upstream CLI, cloud API, or terraform provider releases a minor patch.

This workshop shatters both paradigms across **TWO DISTINCT, INTERLOCKING FRONTS**:

```
                  ┌─────────────────────────────────────────────────────────┐
                  │          WHY IS THIS WORKSHOP DIFFERENT? 🚀             │
                  └──────────────────────────┬──────────────────────────────┘
                                             │
             ┌───────────────────────────────┴──────────────────────────────┐
             ▼                                                              ▼
 🌟 PILLAR 1: THE CONTENT                        🤖 PILLAR 2: THE METAMODEL (THE WAY)
 (World-Class Production Architecture)           (Self-Healing Autonomous Engineering)
 ─────────────────────────────────────           ─────────────────────────────────────
 • Enterprise Cloud Run Multi-Container Sidecars • Autonomous Friction Logging Loop (FL-001..004)
 • Private GCS via IAM Credential Blob Signing   • Automated Bug & PR Synthesis
 • Zero-Trust Cloud SQL Auth Proxy + Secrets     • 100% Declarative Playwright Screenshots
 • Localhost Invariant + Educational Telemetry   • Declarative SKELETON & Executable Step Evals
                                                 • Zero-Branch "Time Machine" Progression
```

---

## 🌟 Pillar 1: The Content — "Production-Grade Rails 8 on GCP Done RIGHT"

### 1. Cloud Run Multi-Container Sidecars (Docker Compose for Monolith Lovers)
- **The Hook:** Rubyists and full-stack developers adore monolithic simplicity (Rails 8, Kamal, single-repo developer happiness) but dread Kubernetes cognitive overhead.
- **The Solution:** We showcase how [Cloud Run multi-container sidecars](https://docs.cloud.google.com/run/docs/deploy-run-compose) natively run **Puma (web)**, **Solid Queue (background worker)**, and **Cloud SQL Auth Proxy (secure mTLS proxy)** within a single serverless workload.
- **The Pedagogical Trap (Step 3):** In [CODELAB.md Step 3](https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/CODELAB.md#step-3), students hit the *"Puma Workaround"* trap (`SOLID_QUEUE_IN_PUMA=true`). It drains jobs in local development, but upon serverless container scaling/reset, ephemeral SQLite wipes out pending jobs. This provides a natural, unforgettable "aha!" moment for why decoupled cloud persistence is essential.

### 2. Private Google Cloud Storage with IAM Credential Blob Signing (`iam: true`)
- **No World-Readable Buckets:** Instead of opening public `allUsers` read permissions (a ubiquitous cloud anti-pattern), our ActiveStorage setup uses Google Cloud IAM blob signing via short-lived signed URLs (`iam: true`).
- **Pedagogical Watermarks:** In-app telemetry badges and image provenance stamps visibly declare whether an asset is an ephemeral local fallback or a private GCS blob.
- *Code Reference:* Configured cleanly in [`blog/config/storage.yml`](https://github.com/palladius/rails8-app-on-gcp/blob/main/blog/config/storage.yml) and verified in [`blog/test/models/storage_configuration_test.rb`](https://github.com/palladius/rails8-app-on-gcp/blob/main/blog/test/models/storage_configuration_test.rb).

### 3. Zero-Trust Cloud SQL & Secret Manager Runtime Injection
- **No `0.0.0.0/0` Public IP Anti-Patterns:** Cloud SQL PostgreSQL is deployed without authorized networks. Connections are brokered strictly through the Cloud SQL Auth Proxy sidecar via secure mTLS.
- **Secret Manager Injection:** Zero plaintext database credentials or API keys exist in git or container environments. Secrets are dynamically resolved at runtime via Secret Manager IAM bindings.
- *IaC Reference:* Declarative Terraform in [`iac/database.tf`](https://github.com/palladius/rails8-app-on-gcp/blob/main/iac/database.tf), [`iac/secrets.tf`](https://github.com/palladius/rails8-app-on-gcp/blob/main/iac/secrets.tf), and [`iac/cloudrun.tf`](https://github.com/palladius/rails8-app-on-gcp/blob/main/iac/cloudrun.tf).

### 4. Multimodal Vertex AI & Bilingual Audio Pipelines
- **NanoBanana Vintage Poster Generator (Step 7):** Asynchronous generation of retro 1960s Italian travel posters using Gemini 2.5 Flash and Imagen 3 on Vertex AI via Application Default Credentials (ADC).
- **Podcastifier TTS Pipeline:** Background text-to-speech synthesis generating Italian narration (`it-IT-Wavenet-A`) through an embedded HTML5 audio player.
- **Strict Localhost Invariant:** Enforced by [CONSTITUTION.md §6](https://github.com/palladius/rails8-app-on-gcp/blob/main/docs/CONSTITUTION.md): the application runs offline on `localhost` without GCP credentials or internet, using graceful local fallbacks.
- *Code & PR Reference:* Implemented in [PR #52](https://github.com/palladius/rails8-app-on-gcp/pull/52).

#### 🍌 Live Demo Assets: 1960s Italian Cinema Posters for Modena DevFest
To demonstrate Nano Banana's creative capacity for local conferences (e.g. Modena DevFest), the pipeline generated 3 authentic 1960s vintage film posters combining Ruby on Rails, Google Cloud, and Matz (stored in [`eventi/20261003-modena-devfest/`](../eventi/20261003-modena-devfest)):

| 1. Fellini: *La Dolce Vita di Rails 8* 🛵 | 2. Sergio Leone: *Per un Pugno di Gemme* 🤠 | 3. Tornatore: *Cinema Paradiso* 🚂 |
| :---: | :---: | :---: |
| Matz on Vespa holding Ruby in Piazza Grande | Western Matz in poncho & iconic dark glasses | Classic retro steam engine on Rails |
| [View High-Res PNG](file:///usr/local/google/home/ricc/.gemini/antigravity/worktrees/rails8-app-on-gcp/brag_workshop_automation_narrative/eventi/20261003-modena-devfest/modena_devfest_poster_3_fellini_dolcevita_pure_art.png) · ([GitHub link](../eventi/20261003-modena-devfest/modena_devfest_poster_3_fellini_dolcevita_pure_art.png)) | [View High-Res PNG](file:///usr/local/google/home/ricc/.gemini/antigravity/worktrees/rails8-app-on-gcp/brag_workshop_automation_narrative/eventi/20261003-modena-devfest/modena_devfest_poster_2_spaghetti_western_matz_accurate.png) · ([GitHub link](../eventi/20261003-modena-devfest/modena_devfest_poster_2_spaghetti_western_matz_accurate.png)) | [View High-Res PNG](file:///usr/local/google/home/ricc/.gemini/antigravity/worktrees/rails8-app-on-gcp/brag_workshop_automation_narrative/eventi/20261003-modena-devfest/modena_devfest_poster_1_cinema_paradiso_pure_art.png) · ([GitHub link](../eventi/20261003-modena-devfest/modena_devfest_poster_1_cinema_paradiso_pure_art.png)) |

---

## 🤖 Pillar 2: The Metamodel — "Automated Quality Engineering & Agent-First Design"

> *"We know people don't do workshops by hand anymore—so we engineered the first workshop designed natively for AI Pair Programmers!"* 🤖💡

### 1. Antigravity & Agent-First by Design ("Tell Antigravity to go to this link...")
- **The Modern Reality:** Developers in 2026 don't copy-paste shell commands one by one from a static PDF. They prompt an AI coding assistant (like **Google Antigravity** or **Gemini CLI**).
- **The Agentic Entrypoint ([`workshop/landing-page/README.md`](https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/landing-page/README.md)):**
  - The literal first instruction given to attendees on the presentation slides is:  
    👉 **`"Tell Antigravity: Go to https://github.com/palladius/rails8-app-on-gcp/tree/main/workshop/landing-page and guide me through the workshop!"`**
  - The landing page contains explicit **Rules of Engagement for the AI**:
    - *Pedagogical Tutor, Not a Ghostwriter:* The agent is strictly commanded: *"DO NOT DO EVERYTHING FOR THE STUDENT. Guide them step-by-step, explain why things work, and ask them to verify results."*
    - *Diagnostics First:* The agent is instructed to run environment checks first before touching any code.
- **Dedicated Agent Skills ([`skills/rails8app-workshop`](https://github.com/palladius/rails8-app-on-gcp/tree/main/skills/rails8app-workshop) & [`skills/workshop-troubleshooting`](https://github.com/palladius/rails8-app-on-gcp/tree/main/skills/workshop-troubleshooting)):**
  - We equip the agent with custom skills tailored for this workshop:
    - [`skills/rails8app-workshop/SKILL.md`](https://github.com/palladius/rails8-app-on-gcp/blob/main/skills/rails8app-workshop/SKILL.md): Acting as the AI Tutor, it teaches the agent pedagogical rules of engagement, repository structure, `just` recipes, and zero-branch Time-Machine workflows.
    - [`skills/workshop-troubleshooting/SKILL.md`](https://github.com/palladius/rails8-app-on-gcp/blob/main/skills/workshop-troubleshooting/SKILL.md): Acting as the diagnostic doctor, it catalogs common failure modes and verified recovery procedures across Cloud Run (`references/cloud-run.md`), GCP Billing & IAM (`references/gcp-billing-iam.md`), Multi-DB & Storage (`references/database-storage.md`), and Local Tooling (`references/local-toolchain.md`).

- **Extensive In-App Telemetry ("Help Me Help You"):**
  - Deep inside the Rails app, we embedded programmatic introspection hooks (`/status.json`, `StatusesController`, and in-app diagnostics).
  - This tells both the student's AI pair programmer **and the proctor via Hive** 😉 exactly what stage the student has reached and what component is failing. It's a continuous, bidirectional feedback loop: *"Help me help you!"*

### 2. Autonomous Friction Logging Loop & Virgin Project Verification
- **Beyond Manual Quality Checks:** Instead of hoping students don't get stuck, we run autonomous subagents using the [`devrel-frictionlog-codelab`](https://github.com/palladius/gemini-cli-custom-commands/tree/main/skills/devrel-frictionlog-codelab) skill (`SKILL.md`).
- **The Virgin Project Loop:** The agent provisions a temporary 3-day GCP project, follows [CODELAB.md](https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/CODELAB.md) step-by-step as an inexperienced attendee, logs empirical friction points (with sentiment emojis 🟢/🟡/🔴), and automatically authors PR fixes:
  - **FL-003 Iteration ([Issue #54](https://github.com/palladius/rails8-app-on-gcp/issues/54), [PR #51](https://github.com/palladius/rails8-app-on-gcp/pull/51)):** Caught multi-database migration gaps in the Docker entrypoint (`db:prepare:queue`, `db:prepare:cache`) and isolated Solid Queue execution. Resolved in release `v0.2.3`.
  - **FL-004 Iteration ([Issue #55](https://github.com/palladius/rails8-app-on-gcp/issues/55), [PR #54](https://github.com/palladius/rails8-app-on-gcp/pull/54), [PR #56](https://github.com/palladius/rails8-app-on-gcp/pull/56), [PR #57](https://github.com/palladius/rails8-app-on-gcp/pull/57), [PR #58](https://github.com/palladius/rails8-app-on-gcp/pull/58)):** Executed on virgin project `rails8-workshop-fl04`. Caught Terraform Google Provider 5.x dynamic IAP schema requirements, disabled Cloud Billing API enablement traps, and Cloud Run BYOSA permission enforcement. Fixed in `v0.2.8` with **20/20 evals passing** via `just workshop-eval all`.
  - **FL-005 Iteration ([Issue #72](https://github.com/palladius/rails8-app-on-gcp/issues/72), [PR #73](https://github.com/palladius/rails8-app-on-gcp/pull/73)):** Executed on virgin project `rails8-workshop-fl05`. Caught missing `run.googleapis.com` and `sqladmin.googleapis.com` service dependencies causing mysterious Cloud Run "Internal Error code 7", and Default Compute SA permission blocks on recent GCP projects.
- **Tracked via GitHub Issues**: All automated friction-logging bug reports and PRs are publicly auditable and tagged under the dedicated label:  
  👉 [**GitHub Issues labeled `friction-logging-bugfix`**](https://github.com/palladius/rails8-app-on-gcp/issues?q=label%3A%22friction-logging-bugfix%22)

![Automated Friction Logging GitHub Issues Tracker](../workshop/assets/images/automated_friction_logging_issues.png)

### 3. 100% Declarative Automated Screenshots via Playwright
- **The Problem:** Documentation screenshots rot after every minor UI or CSS change, requiring hours of manual recaptures.
- **The Innovation ([Issue #42](https://github.com/palladius/rails8-app-on-gcp/issues/42), [PR #49](https://github.com/palladius/rails8-app-on-gcp/pull/49), [PR #50](https://github.com/palladius/rails8-app-on-gcp/pull/50), [PR #53](https://github.com/palladius/rails8-app-on-gcp/pull/53)):**
  - Screenshots are declared as code directly in [`workshop/skeleton.yaml`](https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/skeleton.yaml).
  - Executed via [`workshop/screenshots/runner.js`](https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/screenshots/runner.js) running headless Playwright against loaded fixtures.
  - Automatically captures UI milestones: [Step 2 Ephemeral Alert](https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/screenshots/step2_home_ephemeral.playwright.js) and [Step 4 Stuck Background Jobs Banner](https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/screenshots/step4_gcs_stuck_jobs.playwright.js).
  - Stores machine provenance JSON metadata (Git commit, app version, viewport, timestamp, Rails environment) alongside each PNG.
  - Validated in CI via `just test-screenshots`.

### 4. Live Proctor Observability: The Workshop Hive Leaderboard
- **The Problem:** In a classroom of 30+ attendees, instructors are blind to who is stuck, who has deployed, or whose database failed to migrate.
- **The Solution ([Issue #47](https://github.com/palladius/rails8-app-on-gcp/issues/47), [PR #48](https://github.com/palladius/rails8-app-on-gcp/pull/48)):**
  - Built a real-time proctor dashboard under [`workshop/hive/`](https://github.com/palladius/rails8-app-on-gcp/tree/main/workshop/hive) deployed to Cloud Run.
  - **Zero-Friction Attendee Registration:** Attendees submit **only once** via a simple, public Google Form (or QR code) providing just their **Nickname** and their **Cloud Run URL**. No credentials, no classroom management software, no agent installs.
  - **Automated Step & Infrastructure Detection:**
    - The Hive poller continuously queries each attendee's public `/status.json` endpoint in the background with zero impact on student app performance.
    - As the attendee makes progress and deploys new revisions, `/status.json` dynamically exposes:
      1. **Workshop Step Progress (`4/8`, `7/8`)**: Inferred directly from active database schema and configured capabilities.
      2. **Database Persistence**: Ephemeral local SQLite vs. Managed Google Cloud SQL (`SQL ✕` vs `SQL ✓`).
      3. **Storage Tier**: Ephemeral local disk vs. Private Google Cloud Storage with IAM signing (`GCS ✕` vs `GCS ✓`).
      4. **AI Capabilities**: NanoBanana Vertex AI Gemini/Imagen active status (`AI ✕` vs `AI ✓`).
      5. **Operational Telemetry**: Ruby/Rails version, posts/users count, media blobs count, Cloud Run revision delta tag (`00007-m7d`), and live HTTP health ping (UP 200 OK vs DOWN/Unreachable).
    - **Instructors see the entire room's progress update live on the dashboard without students having to manually report anything!**

![Workshop Hive Leaderboard in Action](../workshop/assets/images/hive_leaderboard_screenshot.png)

*Zoom-in: Live telemetry row showing attendee step detection, Cloud Run revision tag, and granular infrastructure badges (`Rubycon FL003` at Step 4/8 vs `Rubycon FL004` at Step 7/8):*

![Student Row Telemetry Detail](../workshop/assets/images/hive_student_row_telemetry.png)

### 5. The Declarative SKELETON: Actionable Pre/Post-Requisites & Automated Step Evals
- **The Problem:** Most workshops describe steps with vague prose. If a student's step fails, neither the student nor an AI agent knows whether prerequisites were met or if the post-state is actually valid.
- **The Innovation ([`workshop/skeleton.yaml`](https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/skeleton.yaml) $\to$ [`workshop/SKELETON.md`](https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/SKELETON.md)):**
  - **Single Source of Truth**: The workshop curriculum is formally specified in a machine-readable schema (`workshop/skeleton.yaml`) and compiled into human-readable markdown (`SKELETON.md`).
  - **Strict Contracts**: Every single step declares actionable **`prerequisites`**, **`pseudocode`**, and **`postrequisites`**.
  - **Executable Step Evals in Code & LLM-as-a-Judge (`bin/workshop_eval.rb`)**:
    - Every step is backed by automated evaluations spanning **3 distinct verification tiers**:
      1. **`[SHELL]`**: CLI, infrastructure, and network connectivity checks.
      2. **`[RUBY]`**: Runtime code assertions, file system contracts, and unit tests.
      3. **`[LLM]`**: LLM-as-a-judge evaluations verifying student creative outputs (e.g. blog post creativity, Milanese poster prompt style adherence, and capstone quest implementations).
    - Students and AI agents can test any individual step or the whole curriculum via `just workshop-eval <step>` or `just workshop-eval all` (**25/25 evaluations passed**).
    - If a step passes its evals, both human and AI know with mathematical certainty that the step's environment, infrastructure, and code contracts are green before proceeding!

### 6. The Zero-Branch Time Machine
- **No Git Merge Hell:** Attendees never juggle 10 conflicting git branches.
- **The Engine ([`bin/workshop_time_machine.rb`](https://github.com/palladius/rails8-app-on-gcp/blob/main/bin/workshop_time_machine.rb)):**
  - Keeps students on `main`.
  - Enables instant checkpoint rewinds or restorations via `just workshop-rewind <N>` and `just workshop-restore-gold`.
  - Validated by isolated UAT sandbox runner [`bin/workshop_uat.rb`](https://github.com/palladius/rails8-app-on-gcp/blob/main/bin/workshop_uat.rb) (`just workshop-uat`).

### 7. The Project Constitution: Inviolable Architectural Invariants
- **The Problem:** In fast-moving projects and AI-assisted workflows, codebases suffer from drift, hacky shortcuts, or accidental regressions (e.g. committing `.env` files, breaking offline execution, or deploying unencrypted public databases).
- **The Governing Authority ([`docs/CONSTITUTION.md`](https://github.com/palladius/rails8-app-on-gcp/blob/main/docs/CONSTITUTION.md)):**
  - **Supreme Hierarchy**: `CONSTITUTION.md` sits above all agent instructions (`AGENTS.md`), developer guides, and curriculum files. Any constitutional change requires a **2/3 supermajority agreement** between **Riccardo 🦖**, **Emiliano 🏎️**, and **AI 🤖**.
  - **Inviolable Invariants (Never to be Violated)**:
    1. **§0 Language Directive (English First)**: All code, UI, commits, tests, and documentation are strictly English. Italian is welcome flavor/cameos, but English is the immutable single source of truth.
    2. **§4 `main` Converges with the Workshop End-State**: `main` is always the complete, production-grade reference architecture (Step 8 Gold Standard).
    3. **§5 Environmental Telemetry & UI Storytelling**: Visual alerts and badges must dynamically indicate ephemeral vs cloud-persistent tiers with zero runtime overhead.
    4. **§6 The Localhost Invariant**: The entire application and workshop baseline **MUST run on `localhost` at ANY GIVEN TIME** without requiring active internet access or live Google Cloud credentials.
    5. **Fast Diagnostic Tests (< 5s)**: Test suites and diagnostics must execute in under 5 seconds with actionable error diagnostics instead of hanging timeouts.

---

## 🗣️ Pragmatic Audience Pitches

### 🏢 Internal Pitch (Googlers / DevRel Leadership / Cloud PMM)
> *"We took the most complex, enterprise-grade cloud architecture patterns—multi-container Cloud Run sidecars, IAM Credential signed storage, Cloud SQL Auth Proxy, and Vertex AI background workers—and turned them into an intuitive developer journey. Even better: we built an autonomous friction-logging engine that spins up virgin GCP projects, runs the workshop end-to-end, catches papercuts before attendees do, and auto-generates documentation screenshots via Playwright. This isn't just a workshop; it's the gold standard for how DevRel should build, test, and ship cloud content."*

### 🌍 External Pitch (Conferences, Modena Ruby Day, Cloud Architects)
> *"Love the developer speed of Rails monoliths but want real, battle-tested serverless infrastructure on Google Cloud without Kubernetes complexity? This workshop takes you from `rails new` on localhost to an enterprise-grade, zero-trust deployment on Cloud Run. You'll master Docker Compose multi-container sidecars, private GCS blob signing with IAM, Cloud SQL over mTLS, and GenAI background pipelines. Zero slides, zero fluff—accompanied by AI pair programming and live telemetry to guide you every step of the way."*

---

## 🇮🇹 Versione Italiana per la Community (Modena Ruby Day & Meetups)

### Perché questo workshop è unico?
1. **Il Contenuto di Livello Enterprise**: Dimostriamo come far girare un vero monolite Rails 8 in produzione su Google Cloud sfruttando i **Multi-Container Sidecars di Cloud Run** (Puma web + Solid Queue worker + Cloud SQL proxy mTLS con Docker Compose). Niente bucket pubblici o database aperti a `0.0.0.0/0`: usiamo ActiveStorage con **Google Cloud Storage e firma IAM short-lived (`iam: true`)**, Secret Manager per i segreti a runtime, e worker asincroni Solid Queue collegati a Vertex AI (Gemini + Imagen 3 + Text-to-Speech italiano).
2. **L'Ingegneria dei Metadati, l'Automazione & Filosofia Agent-First**: Sappiamo che nel 2026 gli sviluppatori **non fanno più i workshop a mano** con il copia-incolla dai PDF: usano agenti di coding! Quindi abbiamo creato il primo workshop **Agent-First nativo**:
   - L'istruzione data agli studenti sulle slide è: *"Di' ad Antigravity di aprire [la landing page](https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/landing-page/README.md) e guidarmi!"* con regole ferree per l'AI (*non fare il lavoro al posto dello studente, spiega il perché, lancia prima le diagnostiche*).
   - Abbiamo creato **Skill dedicate per l'agente** ([`skills/rails8app-workshop`](https://github.com/palladius/rails8-app-on-gcp/tree/main/skills/rails8app-workshop) e [`skills/workshop-troubleshooting`](https://github.com/palladius/rails8-app-on-gcp/tree/main/skills/workshop-troubleshooting)) con la knowledge base di tutti i fallimenti tipici (Cloud Run, Billing, DB, Storage).
   - **Test e diagnostiche dentro l'app Rails ("Help me help you")**: telemetria interna per dire sia all'agente che al proctor (tramite `/status.json` 😉) a che punto si trova lo studente e cosa manca.
   - **Friction Logging Loop autonomo**: tramite la skill [`devrel-frictionlog-codelab`](https://github.com/palladius/gemini-cli-custom-commands/tree/main/skills/devrel-frictionlog-codelab), agenti AI istanziano progetti vergini su GCP, simulano l'esperienza dello studente, scovano i bachi e aprono PR risolutive (cicli **FL-003** e **FL-004**).
   - **Curriculum e Step Evals**: formalmente dichiarato in [`workshop/skeleton.yaml`](https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/skeleton.yaml) $\to$ [`SKELETON.md`](https://github.com/palladius/rails8-app-on-gcp/blob/main/workshop/SKELETON.md) con evaluation a 3 livelli (Shell, Ruby e LLM-as-a-judge).
   - **Screenshot Playwright 100% dichiarativi** e **Hive Leaderboard** in tempo reale via Google Form.
