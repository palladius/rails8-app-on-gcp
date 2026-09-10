The final workshop will be held in `CODELAB.md` which will be converted to a Google Codelab using `claat` tool or similar.
Every page of the codelab is a H2 and it needs a frontmatter with title, tags and other shenaningans which riccardo is going to provide soon.
The final result is similar to this repo: https://codelabs.developers.google.com/codelabs/app-mod-workshop#0 (note every H2 renders into a differemt #1, 2, 3..)

## Ideation and files
You *MUST* ensure that `CODELAB.md` (long version) and `SKELETON.md` (short version) are kept in sync at all times. A change to one should signify a change to the other! Ensure this in a <!-- --> comment on top of both, for disattenti harnesses ;) The reason is that the SKELETON.md contains distilled ideas which then generate the codelab (and occasionally we piggyback stuff from Codelab to Skeleton). Riccardo and Emiliano will debate soleley on SKELETON until its set in stone.

The process is going to look like: 
1. IDEAS.md + SKELETON.md => 
2. sample CODELAB.md => 
3. 7 branches => 
4. complex codelab (which gives instructions to achieve the branch_n -> branc_(n+1) step). This requires the previous to be set in stop
5. rinse and repeat via automated reproduction of all the steps (probably instructions+branch_n will occasionally fail to bring to N+1 state so this will be slow and painful).

## 🔗 Dependencies & Build Artifact Flow (DO NOT EDIT PRODUCED FILES)

* **`docs/CONSTITUTION.md` (Source of Truth)** $\to$ `ruby visualizer/build_ghpages.rb` $\to$ produces `build/constitution.html` *(PRODUCED)*
* **`CODELAB.md` (Source of Truth)** $\to$ `ruby visualizer/build_ghpages.rb` $\to$ produces `build/index.html` *(PRODUCED)*
* **`SKELETON.md` (Source of Truth)** $\to$ `ruby visualizer/build_ghpages.rb` $\to$ produces `build/skeleton.html` *(PRODUCED)*
* **`assets/*.jpg` (Source of Truth)** $\to$ copied to `../blog/app/assets/images/` and `build/assets/`
* ⚠️ **RULE:** NEVER edit generated HTML (`build/*.html`). Always modify the Markdown source of truth!

## 📅 Workshop Events Directory (`workshop/events/YYYYMMDD-EVENT_NAME/`)

Specific workshop editions and conference deliveries are organized under `workshop/events/YYYYMMDD-EVENT_NAME/`:
- Contains event-specific readmes, schedules, links to live deployed slides, and conference retrospectives.
- Premiere event: `workshop/events/20261003-devfest-modena/`.

---

## 🧭 Zero-Branch Progression Architecture (Rewind & Uplift Directives)

`main` represents the **Gold Standard Production Blueprint** (full perfection: Cloud SQL, GCS IAM signed URLs, Secret Manager, Multi-Container Sidecars).
To avoid Git branch divergence, AI agents can rewind or uplift the working tree state deterministically:

### The 3 Architectural Stages
1. **Stage 1 (Local Baseline / Ephemeral Cloud Deploy 1) [🪫 DB Ephemeral · 🪣 Storage Ephemeral]**:
   - Database: Local SQLite on ephemeral container disk (`db/production.sqlite3`).
   - Storage: Local filesystem (`config/storage.yml` set to `service: Disk`).
   - Cloud Run: Single Puma container (`gcloud run deploy blog --source .`).
2. **Stage 2 (Storage Uplift / Hybrid Deploy 2) [🪫 DB Ephemeral · ☁️ GCS Persistent]**:
   - Database: Local SQLite (still ephemeral!).
   - Storage: Private GCS bucket with IAM Credentials signed URLs (`iam: true`).
   - Cloud Run: Single Puma container redeployed. Images survive; relational data resets.
3. **Stage 3 (Full Enterprise Gold Standard Deploy 3) [🔋 Cloud SQL · ☁️ GCS Persistent]**:
   - Database: Cloud SQL PostgreSQL via `cloudsql-proxy` sidecar tunnel on `127.0.0.1:5432`.
   - Secrets: Google Cloud Secret Manager runtime injection (`--set-secrets`).
   - Multi-Container: Puma `web` + Solid Queue `worker` + `cloudsql-proxy`.

### ⚠️ POLA Directive (Principle of Least Astonishment) for Asynchronous Jobs
When deploying Stages 1 and 2 (single-container Puma without a separate Solid Queue worker container):
- Enqueued jobs (like cover art generation or podcast generation) must NOT silently fail or puzzle the student.
- The UI layout must show a friendly, pedagogical banner:
  `"⚠️ Notice: X background jobs queued but waiting for a worker container. (Ask AI why!)"`
- This banner visually disappears at Stage 3 once the `worker` sidecar container is provisioned.