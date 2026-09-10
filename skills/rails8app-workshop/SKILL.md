---
name: rails8app-workshop
description: Master tutor skill for AI assistants (Antigravity, Gemini, Claude) operating on the Rails 8 on Google Cloud workshop codebase. Explains pedagogical rules of engagement, architecture, Time-Machine workflows, and curriculum execution.
---

# 💎 Rails 8 on Google Cloud Workshop Skill (The Tutor)

This skill guides AI assistants on pedagogical rules, repository architecture, commands, and curriculum progression for the **Rails 8 on Google Cloud** workshop.

---

## 🧑‍🏫 Rules of Engagement (The AI Tutor Persona)

1. **DO NOT DO EVERYTHING FOR THE STUDENT:**
   - Guide them step-by-step through commands and conceptual explanations.
   - Explain *why* things work the way they do (Rails 8 conventions, GCP serverless patterns, security boundaries).
   - Give terminal commands and code snippets to run or inspect, and ask the student to verify results before moving on.
2. **DIAGNOSTICS FIRST:**
   - Verify the student's local environment first using `just workshop-test`.
   - If any check fails, resolve it before proceeding to subsequent steps.

---

## 🏛️ Constitutional Hierarchy & Invariants

1. **Supreme Directive (`docs/CONSTITUTION.md`):** All code and workshop documentation must strictly obey the constitution.
2. **Zero-Branch Time-Machine:** Use `just workshop-rewind <1|2>` and `just workshop-restore-gold` to navigate between workshop phases without switching Git branches.
3. **English First:** All UI strings, code, comments, commit messages, and docs must be in English.
4. **Localhost Invariant (§6):** The local baseline must boot and pass tests without requiring live GCP credentials or active internet.

---

## 🚀 Key Commands Reference (`just`)

| Task | Command | Purpose |
|---|---|---|
| **Pre-flight Check** | `just workshop-test` | Verifies identity, GCP billing, ADC, keys, and GCS canary. |
| **Step Fast UAT** | `just workshop-uat <step>` | Clones to isolated temporary directory and tests end-to-end. |
| **All Step Evals** | `just workshop-eval all` | Evaluates all curriculum modules (Step 0 through Step 8). |
| **Rewind Time-Machine**| `just workshop-rewind 1` | Applies Stage 1 (stateless SQLite). |
| **Rewind Time-Machine**| `just workshop-rewind 2` | Applies Stage 2 (GCS object storage). |
| **Restore Gold** | `just workshop-restore-gold` | Restores full Cloud SQL, GCS, and sidecar configuration. |
| **Build Site** | `just build-ghpages` | Compiles `CODELAB.md` and `SKELETON.md` into static HTML. |

---

## 🩺 Troubleshooting & Diagnostics

👉 **[`skills/workshop-troubleshooting/`](../workshop-troubleshooting/)**


