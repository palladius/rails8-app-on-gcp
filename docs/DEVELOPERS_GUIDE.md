# 🛠️ Developer's Guide to the Rails 8 on GCP Workshop

> **How this workshop was conceived, architected, and engineered with AI pair-programming.**  
> *Authors: Riccardo Carlesso 🦖 & Emiliano Della Casa 🍝🏎️ (with Google Antigravity 🤖)*

---

## 🧭 1. Vision & Origin Story

This workshop was created to answer a fundamental paradox:
**How do we teach modern serverless Google Cloud architecture to developers who love monolithic simplicity (Ruby on Rails 8, Kamal, single-repo developer happiness) without alienating the 90% of future attendees who have never touched Ruby before?**

Instead of building a trivial "Hello World" container with SQLite in production, or drowning attendees in Kubernetes YAML, we designed a **two-fold reference architecture**:
1. **The Canonical Rails 8 on GCP Blueprint (`main`):** Production-grade reference app featuring Cloud Run multi-container sidecars (`web` Puma + `worker` Solid Queue + `cloudsql-proxy`), private GCS via IAM Credential blob signing (`iam: true`), Secret Manager runtime injection, and background GenAI pipelines (Gemini 2.5 Flash + Imagen 3 + Text-to-Speech).
2. **The Autonomous Workshop Metamodel (`workshop/`):** A declarative, self-healing educational platform driven by Google Antigravity that guides students step-by-step from ephemeral local baseline to production cloud-native mastery.

---

## 📜 2. The Meta-Constitution (`docs/CONSTITUTION.md`)

At the core of the repository sits [`docs/CONSTITUTION.md`](CONSTITUTION.md), the **immutable source of truth** ratified by the maintainers and AI assistants:

- **Constitutional Invariants:**
  1. **Strict Localhost Invariant (§6):** The app must always boot and test on `localhost:3000` with zero cloud credentials and zero internet access. Cloud features gracefully fallback to mocks or local diagnostics.
  2. **Security by Default (§1 & §3):** No world-readable GCS buckets (`allUsers`), no `0.0.0.0/0` public database holes, no committed secrets.
  3. **Multi-Container Sidecars on Cloud Run (§2):** Container sidecars provide cloud parity with Docker Compose without cluster overhead.
  4. **Pedagogical Telemetry (§5):** Badges in the UI visibly tell students whether they are connected to an ephemeral database or managed Google Cloud SQL, and whether an asset lives on local disk or in a private GCS bucket.

---

## 🦴 3. Declarative SKELETON (`workshop/skeleton.yaml` & `SKELETON.md`)

Workshops typically rot when prose gets out of sync with code. To eliminate manual rot:
- [`workshop/skeleton.yaml`](../workshop/skeleton.yaml) is the **machine-readable single source of truth** declaring each step's:
  - `prerequisites`: Required CLIs (`git`, `gcloud`, `terraform`, `docker`, `ruby`, `rails`)
  - `pseudocode`: Canonical bash & CLI commands
  - `postrequisites`: Expected outcomes
  - `evals`: Executable health gates (`[SHELL]`, `[RUBY]`, `[LLM]`)
- Running `just build-skeleton` automatically compiles `skeleton.yaml` into [`workshop/SKELETON.md`](../workshop/SKELETON.md).

---

## 🧪 4. Automated Testing & Verification Gates

The repository enforces strict verification gates before any commit or release:
- **`just test`:** Runs Rails unit and integration tests (< 5s).
- **`just test-screenshots`:** Validates declarative Playwright screenshot definitions declared in `skeleton.yaml`.
- **`just test-slides`:** Validates Marp slides against visual boundary overflows, tag-escaping leaks (`<div style>`, `<button>`), and tests PNG rendering pipeline.
- **`just workshop-test`:** Pre-flight diagnostic suite verifying GCP billing, ADC credentials, active project, and storage canaries.

---

## 🌐 5. Workshop Surfaces & GitHub Pages Engine

The workshop is delivered through three cohesive surfaces compiled via `just build-ghpages`:
1. **Workshop Landing Portal (`/`):** A clean, full-page responsive entrypoint with a bilingual language switcher (🇬🇧 EN / 🇮🇹 IT) directing attendees to the appropriate step.
2. **Presentation Slides (`/slides/`):** Marp-based visual presentation deck with QR codes, Antigravity onboarding, and live audio clips.
3. **Interactive Codelab (`/codelab/`):** Google Codelab visualizer rendering [`workshop/CODELAB.md`](../workshop/CODELAB.md) with step navigation and telemetry feedback.

---

## 📚 Further Reading
- [`docs/CONSTITUTION.md`](CONSTITUTION.md): The supreme constitutional directives.
- [`docs/WORKSHOP_BRAG_DOCUMENT.md`](WORKSHOP_BRAG_DOCUMENT.md): Comprehensive architectural deep-dive into both pillars.
- [`docs/WORKSHOP_TELEMETRY_AND_ALERTS.md`](WORKSHOP_TELEMETRY_AND_ALERTS.md): Telemetry badges, alert matrix, and UI storytelling.
