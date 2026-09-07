# 🧭 Pagina di Benvenuto del Workshop & Direttiva Antigravity

> **🤖 Istruzioni per Google Antigravity:**
> Agisci come tutor paziente, incoraggiante e tecnicamente solido per questo workshop.
> 
> **Regola Suprema di Ingaggio:**
> **NON FARE TUTTO TU AL POSTO DELLO STUDENTE.**
> - Guidalo passo dopo passo.
> - Spiega *perché* le cose funzionano in un certo modo (concetti di Ruby on Rails 8, pattern serverless di GCP, confini di sicurezza IAM).
> - Fornisci allo studente comandi terminale e snippet di codice da eseguire o ispezionare, chiedendogli di verificare i risultati prima di proseguire.
> - Durante il debugging, aiutalo a scoprire l'errore anziché risolverlo silenziosamente in background.

---

## 👋 Benvenuto al Workshop Rails 8 su Google Cloud!

Benvenuto! Che tu sia uno sviluppatore Ruby esperto o un cloud engineer che non ha mai visto una riga di Ruby prima d'ora, questo workshop è pensato apposta per te.

Costruiremo insieme una piattaforma blog cloud-native di livello enterprise con **Ruby on Rails 8** e la distribuiremo su **Google Cloud Platform (GCP)** sfruttando la moderna architettura serverless.

---

## 🗺️ Anatomia del Repository

Tutto ciò di cui hai bisogno è organizzato in questo repository:

- 📄 [`justfile`](file:///justfile): **Il centro di comando.** Contiene tutti i comandi per compilare, avviare, testare e distribuire.
  - `just slides`: Avvia le slide di presentazione su `http://localhost:8082`
  - `just workshop-dev`: Avvia l'interfaccia interattiva del Codelab su `http://localhost:8080`
  - `just dev`: Avvia l'applicazione locale Rails 8 su `http://localhost:3000`
  - `just test`: Esegue la suite di test rapida e diagnostica
  - `just compose-up`: Avvia lo stack multi-container locale (app + PostgreSQL + Solid Queue)
- 📁 [`blog/`](file:///blog/): Il codice sorgente dell'applicazione Rails 8.
  - Sviluppato con le novità di Rails 8: Solid Queue (background jobs su DB), Propshaft, Importmaps, ActionText e ActiveStorage.
- 📁 [`workshop/`](file:///workshop/): Curriculum del workshop, passaggi e visualizzatore codelab.
  - Consulta [`workshop/CODELAB.md`](file:///workshop/CODELAB.md) per il programma completo.
  - I vari step sono raggruppati in branch Git dedicati: `workshop/step-1-local-baseline`, `workshop/step-2-docker-compose`, ecc.
- 📁 [`iac/`](file:///iac/): Infrastructure as Code.
  - Configurazioni per Cloud Run, Cloud SQL (PostgreSQL), Google Cloud Storage, Secret Manager e Cloud Build.
- 📁 [`slides/`](file:///slides/): Slide di presentazione con Marp.

---

## 🚀 Come Iniziare (Passo 0)

1. **Verifica l'ambiente locale:**
   Esegui nel terminale per vedere l'elenco dei comandi disponibili:
   ```bash
   just
   ```
2. **Avvia la guida del workshop:**
   Lancia il server locale per visualizzare il Codelab:
   ```bash
   just workshop-dev
   ```
   Poi apri [http://localhost:8080](http://localhost:8080) nel browser.

3. **Avvia l'app Rails:**
   ```bash
   just dev
   ```
   Apri [http://localhost:3000](http://localhost:3000) per vedere l'applicazione Rails 8 in esecuzione su SQLite locale.

4. **Inizia con Antigravity:**
   Scrivi ad Antigravity:
   > *"Ho l'app avviata su localhost. Qual è lo Step 1 del workshop e come gestisce Rails 8 il database in locale rispetto a GCP?"*

Buon workshop e buon divertimento su Google Cloud! 🚀
