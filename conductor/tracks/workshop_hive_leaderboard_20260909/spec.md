# Specification: Workshop Hive Leaderboard (Issue #47)

> **Track ID:** `workshop_hive_leaderboard_20260909`  
> **Target Issue:** [#47](https://github.com/palladius/rails8-app-on-gcp/issues/47)  
> **Status:** Confirmed  
> **Type:** Feature  

---

## 1. Overview & Vision
Creare un'applicazione HIVE posizionata in `workshop/hive/` che funge da Leaderboard in tempo reale per gli studenti del workshop:
- **Gamification & Gratification:** Visualizzare la lista degli studenti (o nick generati/scelti) con lo stato di avanzamento e i timestamp dei vari step del workshop.
- **Data Source:** Lettura dinamica dei dati/progressi da uno spreadsheet di Google (o risposte di un Google Form) oppure via API diretta.
- **Service Account / Auth:** Autenticazione sicura tramite variabile d'ambiente (`HIVE_SERVICE_ACCOUNT_JSON` o base64 `HIVE_SERVICE_ACCOUNT_KEY_B64`) caricabile su Cloud Run o da Secret Manager.
- **Live Health Monitoring & Blinking Lights:** Pinging periodico dell'endpoint `/up` di ciascuna app Cloud Run registrata, mostrando un badge lampeggiante verde (healthy) o rosso (failing/unreachable).
- **Kanban / Progression View:** Visualizzazione a livelli/step (es. Step 1 -> Step 7) che mostra visivamente chi si trova in quale fase del workshop.

---

## 2. Functional Requirements

### 2.1 Collocazione & Architettura Backend
- Cartella: `workshop/hive/` (completamente isolata e deployabile in autonomia su Cloud Run via proprio `Dockerfile` / `Procfile`).
- Backend Ruby (Sinatra con `google-apis-sheets_v4` o Google API Client), con fallback architetturale a Python FastAPI qualora le librerie Ruby per Sheets risultassero limitanti.
- Endpoint API locali:
  - `GET /api/leaderboard`: Ritorna la lista dei partecipanti, step raggiunto, timestamp, e URL Cloud Run.
  - `GET /api/healthchecks`: Ritorna lo stato corrente (up/down, response time) delle app Cloud Run registrate.
  - `POST /api/register`: (Opzionale/Integrato) Per permettere a un'app studente o a uno script di registrarsi direttamente inviando il proprio URL e step.

### 2.2 Google Sheet Integration & Auth
- Supporta credenziali del Service Account via `ENV["HIVE_SERVICE_ACCOUNT_KEY_B64"]` o percorso file locale `ENV["GOOGLE_APPLICATION_CREDENTIALS"]`.
- Polling o cache a breve termine (es. 15-30s) per non sforare le quote API di Google Sheets.

### 2.3 Frontend & UI Experience
- UI moderna e reattiva (HTML5 + Tailwind CSS / Vanilla JS o framework ultra-leggero).
- Visualizzazione Kanban per i livelli del workshop (Step 1 -> Step 7).
- Indicatore visivo lampeggiante rosso/verde basato sul ping `/up` degli URL registrati.
- Auto-refresh morbido della dashboard senza ricaricare l'intera pagina.

---

## 3. Non-Functional Requirements & Security
- **Security:** Nessuna credenziale o chiave Service Account committata nel repository. File `.env` e chiavi JSON aggiunti rigorosamente a `.gitignore`.
- **Portabilità:** Containerizzabile su Google Cloud Run (porta 8080).
- **Zero interferenza:** Nessuna dipendenza obbligatoria con il DB principale dell'app Rails in `blog/`.

---

## 4. Acceptance Criteria
- [ ] Cartella `workshop/hive/` creata con struttura Sinatra/Ruby e `Gemfile`.
- [ ] Modulo di integrazione Google Sheets funzionante con autenticazione via ENV/Service Account.
- [ ] Task asincrono o endpoint per il ping `/up` con calcolo stato UP/DOWN.
- [ ] Interfaccia web con vista leaderboard e visualizzazione a step (Kanban) con indicatori di stato verdi/rossi lampeggianti.
- [ ] Suite di test unitari e di integrazione per il parsing dei dati e gli endpoint API.
- [ ] Documentazione in `workshop/hive/README.md` con istruzioni di configurazione e deploy su Cloud Run.
