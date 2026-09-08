# Specification: Rewrite CODELAB.md to v2.0.0alpha

> **Track ID:** `rewrite_codelab_v2_20260908`  
> **Target Issue:** [#29 (Child of #2)](https://github.com/palladius/rails8-app-on-gcp/issues/29)  
> **Version:** `2.0.0alpha`  
> **Status:** In Progress  

---

## 1. Overview & Vision
`workshop/CODELAB.md` v1.0.0 era basato su vecchi branch orfani (`workshop_1_local_baseline`, etc.), riferimenti obsoleti e una sequenza non allineata con la Costituzione v1.1.0 e `workshop/skeleton.yaml`.
La versione `2.0.0alpha` riscrive il documento narrativo principale del Codelab per rispecchiare fedelmente l'architettura a **8 Step con 3 Deploy progressivi su Cloud Run**, il paradigma **Zero-Branch Time-Machine** (`just workshop-rewind <N>`, `just workshop-restore-gold`), l'harness di test rapido (`just workshop-uat <N>`) e le valutazioni ibride/LLM.

## 2. Scope & Iterative Milestones
- **Passata 1 (Focus Immediato):**
  - Header, Introduzione e Versioning `2.0.0alpha`.
  - **Step 0:** Setup, Antigravity Pairing, ADC & Billing Verification (`gcloud beta billing projects describe`).
  - **Step 1:** Terraform Infrastructure Kickoff & Pre-Flight Diagnostics (`just workshop-test`, provisioning asincrono di Cloud SQL e GCS bucket).
- **Passate Successive:**
  - Step 2: Local Baseline & Mailpit.
  - Step 3-6: I 3 Deploy progressivi (D1 Stateless Shock, D2 GCS Storage Uplift, D3 Gold Multi-Container Sidecars).
  - Step 7-8: GenAI Pipelines & Quests.
