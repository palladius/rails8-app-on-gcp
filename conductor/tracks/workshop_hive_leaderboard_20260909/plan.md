# Plan: Workshop Hive Leaderboard (Issue #47)

> **Track ID:** `workshop_hive_leaderboard_20260909`  
> **Status:** New  

---

## Phase 1: Prototipo Backend Sinatra & Configurazione Auth
- [x] Task: Inizializzare la struttura di `workshop/hive/` con `Gemfile`, `app.rb`, `config.ru` e Dockerfile di base. [6ad867c]
- [x] Task: Scrivere test unitari per il modulo di autenticazione e caricamento credenziali Service Account da ENV (JSON o Base64). [ba67a30]
- [x] Task: Implementare il client Google Sheets (`google-apis-sheets_v4`) con caching in memoria (TTL 30s) per leggere partecipanti e progressi. [901e001]
- [~] Task: Implementare l'endpoint `GET /api/leaderboard` e verificarne il payload JSON.

- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md).

## Phase 2: Live Healthchecker per le App Cloud Run
- [ ] Task: Scrivere test per il worker/service che esegue il ping HTTP su `/up` degli URL Cloud Run registrati.
- [ ] Task: Implementare il runner periodico / asincrono di healthcheck con gestione di timeout brevi (< 3s) e tracking dello stato UP/DOWN.
- [ ] Task: Esporre i risultati via `GET /api/healthchecks`.
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md).

## Phase 3: Frontend Reattivo, Vista Kanban e Blinking Lights
- [ ] Task: Creare la struttura HTML/CSS (Tailwind o CSS vanilla moderno e giocoso) con colonna per ogni livello/step del workshop.
- [ ] Task: Implementare logica client JS per il polling periodico di leaderboard e health status.
- [ ] Task: Aggiungere gli indicatori visivi lampeggianti verdi/rossi per lo stato di ciascun partecipante e la visualizzazione a schede studente in Kanban.
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md).

## Phase 4: Containerizzazione, Documentazione & Deploy Ready
- [ ] Task: Creare `Dockerfile` multi-stage ottimizzato per Cloud Run e script `bin/dev` o `run.sh` locale.
- [ ] Task: Redigere `workshop/hive/README.md` con spiegazione chiara di come configurare il Google Sheet, il Service Account e le variabili d'ambiente.
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md).
