# 🧭 Workshop Environmental Telemetry & Alerts Guide

> **Document Authority:** Governed by [`docs/CONSTITUTION.md`](file:///usr/local/google/home/ricc/git/rails8-app-on-gcp/docs/CONSTITUTION.md) (§5 *Environmental Telemetry & UI Storytelling* and §6 *Localhost Invariant*).  
> **Target Audience:** Workshop students, maintainers, and AI pair programmers.

---

## 🎯 Purpose & Philosophy

Running an application in a modern cloud-native workshop creates a unique pedagogical challenge:
~90% of students are learning cloud concepts (serverless, managed databases, private blob storage, and background sidecars) while transitioning from simple local development to production architecture on Google Cloud.

If an application behaves unexpectedly (e.g. cover images are grayscale, jobs stay pending, or users cannot log in), students can experience cognitive overload.

To solve this, our UI uses **Environmental Telemetry & Educational Alert Banners**:
1. **Instant feedback (< 0ms network latency):** Detection occurs purely in-memory / local checks without blocking web request cycles or slowing down `just dev`.
2. **Pedagogical honesty:** Clear distinction between ephemeral local development and persistent cloud infrastructure.
3. **Contextual guidance:** Every warning includes an action prompt and a dedicated **"Why? (Ask AI) 🤖"** interactive modal/explanation.

---

## 🏷️ The Alert Banners (Top of Page)

The banners live under [`blog/app/views/workshop/alerts/`](file:///usr/local/google/home/ricc/git/rails8-app-on-gcp/blog/app/views/workshop/alerts/) and are aggregated by the [`_hub.html.erb`](file:///usr/local/google/home/ricc/git/rails8-app-on-gcp/blog/app/views/workshop/alerts/_hub.html.erb) container.

```
+---------------------------------------------------------------------------------------------------------+
| [EMOJI] Notice: [Title of Status]                                              [ Why? (Ask AI) 🤖 ]    |
|         [Secondary explanation / Next step hint]                                                        |
+---------------------------------------------------------------------------------------------------------+
```

### 1. 👤 Missing Admin Alert (`_missing_admin.html.erb`)
* **Condition:** `User.count == 0`
* **Trigger:** Fresh local clone before running `bin/rails db:seed`, or initial deployment on Cloud Run before bootstrap.
* **Style:**
  - **Border / Accent:** Red `#ef4444` (`border-left: 5px solid #ef4444`)
  - **Background:** Soft rose `#fef2f2`
  - **Text Color:** `#991b1b` / `#b91c1c`
* **Why Button (`Ask AI 🤖`):** Explains that the user database is empty and instructs the student to run `just seed` (with `ADMIN_EMAIL` configured) or supply `ADMIN_EMAIL` and `ADMIN_PASSWORD` in Cloud Run environment variables.

---

### 2. 🟡 Ephemeral Database Alert (`_ephemeral_database.html.erb`)
* **Condition:** Active database adapter is SQLite or local Postgres, without Cloud SQL proxy connection.
* **Trigger:** Workshop Steps 1 and 2 (Local dev & standalone containers).
* **Style:**
  - **Border / Accent:** Amber/Yellow `#eab308` (`border-left: 5px solid #eab308`)
  - **Background:** Soft yellow `#fefce8`
  - **Text Color:** `#854d0e` / `#a16207`
* **Why Button (`Ask AI 🤖`):** Explains that SQLite / local Postgres is ephemeral to the host instance, and points to Step 3 where Google Cloud SQL is introduced with Cloud SQL Auth Proxy sidecar container and automated mTLS encryption.

---

### 3. 💾 Ephemeral Local Disk Storage Alert (`_ephemeral_storage.html.erb`)
* **Condition:** `storage_tier == :local` (ActiveStorage pointing to `:local` disk service).
* **Trigger:** Workshop Steps 1 to 3, before Google Cloud Storage bucket configuration.
* **Style:**
  - **Border / Accent:** Slate grey `#64748b` (`border-left: 5px solid #64748b`)
  - **Background:** Crisp cool grey `#f8fafc`
  - **Text Color:** `#334155` / `#64748b`
* **Why Button (`Ask AI 🤖`):** Explains that local disk storage is ephemeral in containerized serverless runtimes. Explains why user images appear in sad grayscale mode, and previews Step 4 where Google Cloud Storage (`iam: true`) provides durable signed blob persistence.

---

### 4. 🍌 Nano Banana AI Status Alert (`_ai_status.html.erb`)
* **Condition:** `!Nanobanana.available?` (neither `GEMINI_API_KEY` nor Vertex AI ADC credentials are configured).
* **Trigger:** Post cover generation falling back to the bundled vintage movie poster (`nanobanana_fake_cover.png`).
* **Zero-Lag Invariant:** Evaluates purely via `ENV["GEMINI_API_KEY"].present?` or local ADC file inspection. **Zero network calls (< 1ms)** to ensure no startup penalty on `bin/dev`.
* **Style:**
  - **Border / Accent:** Soft crimson `#ef4444` (`border-left: 5px solid #ef4444`)
  - **Background:** Soft red `#fef2f2`
  - **Text Color:** `#991b1b` / `#b91c1c`
* **Why Button (`Ask AI 🤖`):** Explains how to activate real live cover generation via Google AI Studio (`GEMINI_API_KEY`) or enterprise Vertex AI (`gcloud auth application-default login` + `GOOGLE_CLOUD_PROJECT`).

---

### 5. ⚠️ Stuck Background Jobs Alert (`_stuck_jobs.html.erb`)
* **Condition:** `SolidQueue::Job.where(finished_at: nil).count > 0`
* **Trigger:** ActiveJobs enqueued while running in single-container mode without a dedicated Solid Queue worker.
* **Style:**
  - **Border / Accent:** Warning amber `#f59e0b` (`border-left: 5px solid #f59e0b`)
  - **Background:** Pale gold `#fffbeb`
  - **Text Color:** `#92400e` / `#b45309`
* **Why Button (`Ask AI 🤖`):** Explains that Puma only handles HTTP traffic; background jobs await execution until Step 3 attaches the Solid Queue worker sidecar container.

---

## 🎨 Aesthetic & Design System Guidelines

All workshop alerts must follow these strict CSS design system principles:

1. **Card Container:**
   - Subtle left border accent (`border-left: 5px solid <accent-color>`) for immediate visual hierarchy.
   - Light, pastel background tint (`#fef2f2`, `#fefce8`, `#f8fafc`, `#fffbeb`) matching the severity.
   - Rounded corners (`border-radius: 6px`) and subtle elevation (`box-shadow: 0 1px 3px rgba(0,0,0,0.05)`).
   - Max width matching container grid (`max-width: 1200px; margin: 8px auto;`).

2. **Typography & Hierarchy:**
   - Leading title in `<strong>` tag, font size standard readable (`1rem`).
   - Secondary subtitle description in smaller muted tone (`font-size: 0.85rem; margin-top: 2px`).

3. **The "Why? (Ask AI) 🤖" Button (Top-Right):**
   - **Position:** Aligned to the far right via flexbox (`display: flex; justify-content: space-between; align-items: center;`).
   - **Contrast:** Monochromatic button background slightly darker than the banner card (e.g. `#fee2e2` on `#fef2f2`, `#fef9c3` on `#fefce8`).
   - **Border:** 1px border matching the accent color.
   - **Typography:** `font-size: 0.82rem`, `font-weight: 600`, with emoji.
   - **Action:** Triggers an educational modal or alert dialog detailing the architecture decision and step command.

4. **Production Deactivation Switch:**
   - All alerts are wrapped inside `<% unless ENV["DISABLE_WORKSHOP_ALERTS"] == "true" %>`.
   - In production or custom deploys, setting `DISABLE_WORKSHOP_ALERTS=true` completely hides all banner elements without touching code.

---

## 🧩 Summary Reference Matrix

| Alert Banner | Icon | Trigger Metric | Accent Color | Pedagogical Target |
|---|---|---|---|---|
| **Admin User** | 👤 | `User.count == 0` | `#ef4444` (Red) | Teaches DB seeding & initial admin credentials bootstrap |
| **Database** | 🟡 | SQLite / Local Postgres | `#eab308` (Yellow) | Distinguishes ephemeral storage from Google Cloud SQL |
| **Storage** | 💾 | `storage_tier == :local` | `#64748b` (Slate) | Explains grayscale mode and previews private GCS bucket |
| **AI Status** | 🍌 | `!Nanobanana.available?` | `#ef4444` (Red) | Explains fake cover fallback vs Gemini API / Vertex AI |
| **Queue Worker**| ⚠️ | `SolidQueue::Job.pending > 0` | `#f59e0b` (Amber) | Teaches multi-container Cloud Run worker sidecars |

---

## 🧭 The Professor & Developer Telemetry Dashboard (`/status`)

To give instructors and developers complete situational awareness without poking around terminal variables, a dedicated endpoint is available at:
* **HTML View:** [`/status`](http://localhost:3001/status) (linked in the navigation bar)
* **JSON API:** [`/status.json`](http://localhost:3001/status.json)

### Monitored Subsystems (All 0 ms in-memory checks):
1. **Compute & Runtime:** Distinguishes Google Cloud Run (`K_SERVICE` / serverless), Docker Compose container (`/.dockerenv` / `DOCKER_CONTAINER`), and Native Host Ruby.
2. **Database Persistence:** Identifies Google Cloud SQL (via Auth Proxy mTLS) vs Local PostgreSQL container vs Ephemeral local SQLite3.
3. **ActiveStorage Blobs:** Inspects ActiveStorage service (`:google_prod` / `:google_dev` with IAM blob signing vs `:local` disk).
4. **Nano Banana AI Pipeline:** Confirms if live generation is active via Google AI Studio (`GEMINI_API_KEY`) or Vertex AI (ADC + project), or running in bundled fake cover fallback.
5. **Background Queues:** Displays pending and failed jobs in Solid Queue.
6. **Workshop Counters:** Instant tally of published articles and registered admin accounts.
