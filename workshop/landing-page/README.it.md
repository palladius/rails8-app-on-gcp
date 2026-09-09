# 🧭 Pagina di Benvenuto del Workshop & Direttiva Antigravity

> **🤖 Istruzioni per Google Antigravity:**
> Agisci come tutor paziente, incoraggiante e tecnicamente solido per questo workshop.
> 
> **Regole Supreme di Ingaggio:**
> 1. **NON FARE TUTTO TU AL POSTO DELLO STUDENTE.**
>    - Guidalo passo dopo passo.
>    - Spiega *perché* le cose funzionano in un certo modo (concetti di Ruby on Rails 8, pattern serverless di GCP, confini di sicurezza IAM).
>    - Fornisci allo studente comandi terminale e snippet di codice da eseguire o ispezionare, chiedendogli di verificare i risultati prima di proseguire.
>    - Durante il debugging, aiutalo a scoprire l'errore anziché risolverlo silenziosamente in background.
> 2. **DIAGNOSTICA PRIMA DI TUTTO:**
>    - Il tuo primissimo atto deve essere verificare l'ambiente locale dello studente eseguendo o facendogli eseguire `just workshop-test`.
>    - Se qualche controllo fallisce (Ruby mancante, credenziali gcloud ADC assenti, Billing disattivato), concentrati sullo sbloccare lo studente prima di scrivere qualsiasi riga di codice.

---

## 👋 Benvenuto al Workshop Rails 8 su Google Cloud!

Benvenuto! Che tu sia uno sviluppatore Ruby esperto o un cloud engineer che non ha mai visto una riga di Ruby prima d'ora, questo workshop è pensato apposta per te.

Costruiremo insieme una piattaforma blog cloud-native di livello enterprise con **Ruby on Rails 8** e la distribuiremo su **Google Cloud Platform (GCP)** sfruttando la moderna architettura serverless.

---

## 🌉 Il Ponte: Dallo Step -1 allo Step 0

### Step -1 (Riepilogo dalle Slide):
Hai scaricato **Google Antigravity 2.0**, effettuato il login con il tuo account Google e indirizzato Antigravity su questa pagina. **Sei esattamente nel posto giusto!**

### Step 0: Le Fondamenta dell'Ambiente Locale ("La Valle delle Lacrime" Risolta!)
Prima di toccare il cloud, abbiamo bisogno dei nostri strumenti locali pronti:
1. **Ruby 3.3+** (il runtime di Rails 8)
2. **Google Cloud SDK (`gcloud`)** (autenticato con il tuo account)
3. **Docker** (per i servizi locali e Mailpit)
4. **Just** (il task runner moderno)
5. **Terraform** (per l'infrastruttura cloud dello Step 1)

#### 💻 Configurazione Rapida per Sistema Operativo:

##### 🍎 macOS (tramite Homebrew):
```bash
# Strumenti CLI essenziali:
brew install just terraform google-cloud-sdk
# Ruby tramite rbenv:
brew install rbenv
rbenv install 3.3.8 && rbenv global 3.3.8
```

##### 🐧 Linux / Debian / Ubuntu:
```bash
# Dipendenze essenziali di sviluppo:
sudo apt-get update && sudo apt-get install -y git curl build-essential libssl-dev libyaml-dev
# Just runner:
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/bin
# Ruby tramite rbenv:
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
~/.rbenv/bin/rbenv init
# Installa Ruby 3.3+
```

##### ☁️ Google Cloud Shell / VM:
```bash
# Cloud Shell ha già gcloud, Docker e Terraform preinstallati!
# Verifica o installa solo Ruby 3.3+ via rbenv o chruby.
```

---

## 🧪 Verifica Step 0: Il Gate delle Diagnostiche Pre-Flight

Una volta installati gli strumenti, crea la tua configurazione locale e lancia la suite di test diagnostica:

```bash
# 1. Copia il template delle variabili d'ambiente
cp .env.dist .env

# 2. Autenticati con Google Cloud
gcloud auth login
gcloud auth application-default login

# 3. Esegui le diagnostiche automatizzate
just workshop-test
```

La suite diagnostica (`just workshop-test`) verifica in tempo reale:
- 👤 **Identità & Admin Email**: Verifica `ADMIN_EMAIL` in `.env`.
- ☁️ **Progetto GCP & Billing**: Valida `GOOGLE_CLOUD_PROJECT` e la **presenza obbligatoria del billing attivo** (`gcloud beta billing projects describe`).
- 🔐 **Credenziali ADC**: Valida Application Default Credentials per Vertex AI senza API key.
- 🔑 **Rails Master Key**: Controlla le chiavi locali di decifratura.
- 🐤 **Storage Canary**: Controlla l'asset canary su Google Cloud Storage.

---

## 🗺️ Anatomia del Repository & Centro di Comando Locale

Tutto è orchestrato attraverso il [`justfile`](file:///justfile):

- 📄 [`justfile`](file:///justfile):
  - `just workshop-test`: Esegue la suite diagnostica pre-flight 🧪
  - `just workshop-dev`: Avvia l'interfaccia interattiva del Codelab su `http://localhost:8080`
  - `just slides`: Avvia le slide di presentazione su `http://localhost:8082`
  - `just dev`: Avvia l'applicazione locale Rails 8 su `http://localhost:3000`
  - `just test`: Esegue la suite di test rapida e diagnostica (< 5s)
  - `just compose-up`: Avvia lo stack multi-container locale (app + PostgreSQL + Solid Queue + Mailpit)
- 📁 [`blog/`](file:///blog/): Il codice sorgente dell'applicazione Rails 8.
- 📁 [`workshop/`](file:///workshop/):
  - [`workshop/SKELETON.md`](file:///workshop/SKELETON.md): Roadmap master degli 8 step.
  - [`workshop/CODELAB.md`](file:///workshop/CODELAB.md): Curriculum narrativo esteso.
  - [`workshop/visualizer/`](file:///workshop/visualizer/): Motore Sinatra Codelab e compilatore per GitHub Pages.
- 📁 [`iac/`](file:///iac/): Infrastructure as Code (Terraform Cloud SQL, GCS, Cloud Run).

---

## 🚀 Pronti a Iniziare lo Step 1?

Quando `just workshop-test` restituisce un report pulito e verde, di' ad Antigravity:

> *"Tutti i controlli diagnostici sono verdi! Procediamo con lo Step 1: configurare il .env e lanciare l'infrastruttura immutabile di Terraform!"*

Buon viaggio e buon hacking! 🚀
