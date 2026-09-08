# Specification: Workshop UI Alerts Hub & Admin Bootstrap Guard

> **Track ID:** `workshop_warnings_and_admin_bootstrap_20260908`  
> **Target Issue:** [#21 (Child of #2)](https://github.com/palladius/rails8-app-on-gcp/issues/21)  
> **Status:** Confirmed  
> **Type:** Feature & Refactor

---

## 1. Overview & Vision
Per consentire agli studenti di capire al volo eventuali disallineamenti di configurazione sia in locale che al primo deploy su Cloud Run (senza accesso SSH), implementiamo:
1. Un **Hub unificato e isolato** per tutti i warning didattici del workshop sotto `app/views/workshop/alerts/` (e helper sotto `app/helpers/workshop_helper.rb`), in modo da poter rimuovere o disattivare tutti i warning in produzione con un singolo colpo (`DISABLE_WORKSHOP_ALERTS=true` o cancellando una cartella).
2. Un nuovo warning **`_missing_admin.html.erb`** che si attiva quando `User.count == 0`, spiegando allo studente come settare `ADMIN_EMAIL` ed eseguire il seed.
3. Un **Guard Gate in `db/seeds.rb`**: `db:seed` fallisce con un messaggio chiaro ed ergonomico se `ADMIN_EMAIL` o `ADMIN_PASSWORD` mancano o usano placeholder insicuri, obbligando lo studente a dichiarare la propria identità.
4. Riorganizzazione del warning esistente `_check_stuck_jobs.html.erb` all'interno dell'hub unificato.

---

## 2. Functional Requirements

### 2.1 Hub Unificato dei Warning (`app/views/workshop/alerts/`)
Spostare ed organizzare i warning pedagogici in una cartella dedicata:
- `app/views/workshop/alerts/_stuck_jobs.html.erb`: Spostato da `layouts/_check_stuck_jobs.html.erb`.
- `app/views/workshop/alerts/_missing_admin.html.erb`: Nuovo alert per DB vergine (`User.count == 0`).
- `app/views/workshop/alerts/_hub.html.erb`: Master partial renderizzato in `application.html.erb` prima del `<main>`, che include automaticamente tutti i workshop alert abilitati se `Rails.env.development? || ENV['ENABLE_WORKSHOP_ALERTS'] == 'true' || ENV['WORKSHOP_MODE'] == 'true'`.

### 2.2 Guard Gate in `db/seeds.rb`
- Controlla `ENV["ADMIN_EMAIL"]` e `ENV["ADMIN_PASSWORD"]`.
- Se vuoto, non impostato o placeholder (`your-email@...`):
  - Blocca l'esecuzione con `abort "\n❌ [db:seed] Missing ADMIN_EMAIL in environment! ..."`
- Se presente e valido: crea o aggiorna l'admin, assegna `created_via = "seed"` e invia la mail di benvenuto/reset se in dev.

### 2.3 Visual Design dei Warning
- Stile coerente: box moderni con bordi colorati (arancione per stuck jobs, ambra/rosso soft per missing admin).
- Pulsante interattivo "Why? (Ask AI) 🤖" con spiegazione didattica immediata.

---

## 3. Acceptance Criteria
- [ ] Cartella `app/views/workshop/alerts/` creata con `_stuck_jobs.html.erb`, `_missing_admin.html.erb`, e master `_hub.html.erb`.
- [ ] `layouts/application.html.erb` include unicamente `render "workshop/alerts/hub"`.
- [ ] In assenza di utenti nel DB (`User.count == 0`), l'header mostra il warning "⚠️ Nessun utente amministratore nel database".
- [ ] Con almeno un utente, il warning scompare.
- [ ] `bin/rails db:seed` fallisce se `ADMIN_EMAIL` non è definito.
- [ ] Test di integrazione scritti per verificare la comparsa/scomparsa degli alert e il comportamento di `db:seed`.
