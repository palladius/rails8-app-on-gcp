# Specification: Deterministic GCP Architecture Diagram & Evolution GIF (Issue #66)

## 1. Overview
This track addresses GitHub Issue #66 by introducing a deterministic, code-driven Google Cloud architecture diagram generator for the `rails8-app-on-gcp` reference blueprint and workshop.
Using Python's `diagrams` library (`mingrammer/diagrams`) executed via `uv` with official Google Cloud icons, the generator produces:
1. **Canonical Production Architecture Diagram (`arch_diagram.png`):** A high-resolution, publication-grade diagram highlighting **ALL Google Cloud products** used in the final production state, with explicit directional connection lines and container groupings.
2. **Progressive Evolution Sequence & Animated GIF (`arch_evolution.gif`):** A multi-frame sequence illustrating the pedagogical transition across workshop milestones (Local SQLite -> Cloud SQL -> Private GCS -> Cloud Run Multi-Container -> Vertex AI GenAI), compiled into an animated GIF as a workshop "WOW" factor.
3. **Repository & Workshop Integration:** Automatic placement into `assets/`, `workshop/assets/images/`, `workshop/CODELAB.md` (Page 1 / Introduction), `workshop/SKELETON.md`, and presentation slides (`slides/index.md`).
4. **Declarative Tooling & Unit Tests:** `just diagrams` recipes in `justfile` and automated test verification in `test/test_architecture_diagram.rb`.

## 2. Functional Requirements

### FR-1: Python `diagrams` Tooling via `uv`
- Establish a standalone Python workspace in `diagrams/` managed by `uv` (`pyproject.toml`).
- Use official GCP icon classes from `diagrams.gcp.*`:
  - Compute: `Run` (`diagrams.gcp.compute`)
  - Database: `SQL` (`diagrams.gcp.database`)
  - Storage: `Storage` (`diagrams.gcp.storage`)
  - Security: `SecretManager`, `Iam` (`diagrams.gcp.security`)
  - Machine Learning: `VertexAI` (`diagrams.gcp.ml`)
  - Developer Tools: `Build`, `ContainerRegistry` (`diagrams.gcp.devtools`)
  - Operations: `Logging`, `Monitoring` (`diagrams.gcp.operations`)
  - Networking: `LoadBalancing` (`diagrams.gcp.network`)
- Include `pillow` for animated GIF compilation.
- Obey Derek environment configuration: `UV_INDEX_URL="https://pypi.org/simple"`.
- CLI script `diagrams/generate_diagrams.py` supporting:
  - `--canonical`: Generates `arch_diagram.png`.
  - `--evolution`: Generates progressive step frames and `arch_evolution.gif`.
  - `--all`: Generates both canonical diagram and evolution GIF.

### FR-2: Comprehensive Final GCP Architecture (`arch_diagram.png`)
The final state diagram MUST highlight ALL Google Cloud products in the reference architecture with clear labeled connection lines:
- **Traffic / Ingress:**
  - `Users / Browsers` $\to$ `Google Cloud Load Balancing / DNS` $\to$ Cloud Run Ingress (HTTPS).
- **Compute Tier (Cloud Run Multi-Container Pod):**
  - Grouped visually within a Cloud Run service boundary:
    1. `web` container: Rails 8 Puma application server.
    2. `worker` container: Rails 8 Solid Queue background job processor.
    3. `cloudsql-proxy` sidecar container: Cloud SQL Auth Proxy establishing secure mTLS tunnel.
- **Data Tier:**
  - `web` and `worker` $\to$ `cloudsql-proxy` (localhost/socket) $\to$ `Cloud SQL (PostgreSQL)`.
  - `web` and `worker` $\to$ `Google Cloud Storage` (Private bucket, ActiveStorage with IAM signed URLs).
- **Security & Identity Tier:**
  - `Cloud Run` $\leftarrow$ `Cloud Secret Manager` (runtime secret injection for `RAILS_MASTER_KEY` and DB credentials).
  - `Cloud IAM` providing service account (`rails-app-sa`) credentials for IAM blob signing and Cloud SQL client access.
- **AI & GenAI Tier:**
  - `worker` (Solid Queue) $\to$ `Vertex AI` (Gemini 2.5 Flash for post analysis & Imagen 3 / Nano Banana for cover generation).
- **CI/CD Automation Tier:**
  - Developer Git Push $\to$ `Cloud Build` $\to$ `Artifact Registry` (OCI images) $\to$ `Cloud Run` automated deployment.
- **Observability Tier:**
  - `Cloud Run` $\to$ `Cloud Logging` & `Cloud Monitoring` (structured telemetry & health checks).

### FR-3: Progressive Evolution Sequence & Animated GIF (`arch_evolution.gif`)
- Render milestone frames representing the workshop journey:
  - **Frame 1 (Step 1 Baseline):** Local laptop, SQLite database, local disk storage, in-process async jobs.
  - **Frame 2 (Step 3 Database):** Rails app connected to Google Cloud SQL PostgreSQL via Cloud SQL Auth Proxy.
  - **Frame 3 (Step 4 Storage):** ActiveStorage wired to private Google Cloud Storage with IAM Credential signing (`iam: true`).
  - **Frame 4 (Step 6 Cloud Run Pod):** Multi-container deployment on Cloud Run (`web` + `worker` + `cloudsql-proxy`).
  - **Frame 5 (Step 7 GenAI):** Solid Queue jobs orchestrating Vertex AI (Nano Banana & Gemini).
- Compile into `arch_evolution.gif` (duration ~1.5s per frame, infinite loop).

### FR-4: Workshop & Presentation Slides Integration
- Place rendered assets into:
  - `assets/arch_diagram.png` and `assets/arch_evolution.gif`
  - `workshop/assets/images/arch_diagram.png` and `workshop/assets/images/arch_evolution.gif`
- Embed diagram in `workshop/CODELAB.md` (Introduction / Step 0 / Step 1) with descriptive caption.
- Synchronize `workshop/SKELETON.md` with `workshop/CODELAB.md` to prevent content divergence.
- Embed the architecture diagram in `slides/index.md` (Marp presentation).
- Verify asset copying and serving via `ruby workshop/visualizer/build_ghpages.rb`.

### FR-5: Justfile Automation & Unit Testing
- Add recipes to root `justfile`:
  - `diagram`: Builds canonical `arch_diagram.png`.
  - `diagram-evolution`: Builds frames and `arch_evolution.gif`.
  - `diagrams`: Builds both.
- Automated test `test/test_architecture_diagram.rb`:
  - Validates generator script execution with clean 0 exit code.
  - Verifies presence and non-zero byte size of output PNG and GIF files.
  - Verifies markdown files (`CODELAB.md`, `SKELETON.md`, `slides/index.md`) contain valid references.

## 3. Non-Functional Requirements
- **Deterministic Output:** Diagrams must compile identically across Linux and macOS.
- **Performance:** Execution via `uv` must complete in < 5 seconds.
- **Maintainability:** Adding a new GCP service in the future should require < 5 lines of Python.

## 4. Acceptance Criteria
- [ ] `diagrams/` folder contains `pyproject.toml` and `generate_diagrams.py`.
- [ ] `just diagrams` regenerates both `arch_diagram.png` and `arch_evolution.gif` without errors.
- [ ] Diagram visually shows all specified GCP services with official icons and connection lines.
- [ ] `workshop/CODELAB.md`, `workshop/SKELETON.md`, and `slides/index.md` display the diagram.
- [ ] `ruby test/test_architecture_diagram.rb` and `just test` pass cleanly.

## 5. Out of Scope
- Modifying production Terraform modules or running live Cloud Run deployments.
