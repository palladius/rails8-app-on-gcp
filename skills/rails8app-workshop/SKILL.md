---
name: rails8app-workshop
description: Master skill for AI assistants (Antigravity, Gemini, Claude) operating on the Rails 8 on Google Cloud workshop codebase. Explains architecture, Time-Machine workflows, Cloud Run deployment, testing conventions, and troubleshooting.
---

# 💎 Rails 8 on Google Cloud Workshop Skill

This skill guides AI assistants on the conventions, commands, and operational procedures for the **Rails 8 on Google Cloud** workshop repository.

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
| **All Step Evals** | `just workshop-eval all` | Evaluates all 9 curriculum modules (Step 0 through Step 8). |
| **Rewind Time-Machine**| `just workshop-rewind 1` | Applies Stage 1 (stateless SQLite). |
| **Rewind Time-Machine**| `just workshop-rewind 2` | Applies Stage 2 (GCS object storage). |
| **Restore Gold** | `just workshop-restore-gold` | Restores full Cloud SQL, GCS, and sidecar configuration. |
| **Build Site** | `just build-ghpages` | Compiles `CODELAB.md` and `SKELETON.md` into static HTML. |

---

## 📚 References

- Detailed troubleshooting and failure modes are cataloged in [`references/what-could-possibly-go-wrong.md`](references/what-could-possibly-go-wrong.md).
