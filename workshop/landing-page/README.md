# 🧭 Workshop Landing Page & Antigravity Directive

> **🤖 Instruction for Google Antigravity:**
> You are acting as a patient, encouraging, and highly technical pair-programming tutor for this workshop.
> 
> **Supreme Rules of Engagement:**
> 1. **DO NOT DO EVERYTHING FOR THE STUDENT.**
>    - Guide them step by step.
>    - Explain *why* things work the way they do (Ruby on Rails 8 concepts, GCP serverless patterns, security boundaries).
>    - Give the student terminal commands and code snippets to run or inspect, and ask them to verify results before moving on.
>    - When debugging, guide them to discover the error rather than blindly fixing it in the background.
> 2. **DIAGNOSTICS FIRST:**
>    - Your very first act is to verify the student's local environment by running or guiding them to run `just workshop-test`.
>    - If any check fails (missing Ruby, missing gcloud ADC, missing Billing), prioritize unblocking the student before writing any code.

---

## 👋 Welcome to the Rails 8 on Google Cloud Workshop!

Welcome! Whether you are a seasoned Ruby developer or a cloud engineer who has never touched Ruby before, this workshop is designed for you.

You are building a production-grade, cloud-native blog platform with **Ruby on Rails 8** and deploying it on **Google Cloud Platform (GCP)** using modern serverless infrastructure.

---

## 🌉 The Bridge: From Step -1 to Step 0

### Step -1 (Recap from Slides):
You downloaded **Google Antigravity 2.0**, logged in with your Google account, and pointed Antigravity to this landing page. **You are in the right place!**

### Step 0: The Local Environment Foundation ("La Valle delle Lacrime" Solved!)
Before we touch the cloud, we need our local tools ready. You need:
1. **Git** (for version control, cloning, and branching)
2. **Ruby 3.3+** (Rails 8 runtime)
3. **Google Cloud SDK (`gcloud`)** (authenticated with your account)
4. **Docker** (for local services & Mailpit)
5. **Just** (command runner)
6. **Terraform** (for Step 1 cloud infrastructure)

#### 💻 Quick Setup by Operating System:

##### 🍎 macOS (via Homebrew):
```bash
# Core CLI tools:
brew install just terraform google-cloud-sdk
# Ruby via rbenv:
brew install rbenv
rbenv install 3.3.8 && rbenv global 3.3.8
```

##### 🐧 Linux / Debian / Ubuntu:
```bash
# Core dev dependencies:
sudo apt-get update && sudo apt-get install -y git curl build-essential libssl-dev libyaml-dev
# Just runner:
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/bin
# Ruby via rbenv:
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
~/.rbenv/bin/rbenv init
# Install Ruby 3.3+
```

##### ☁️ Google Cloud Shell / VM:
```bash
# Cloud Shell has gcloud, Docker, and Terraform pre-installed!
# Just verify or install Ruby 3.3+ using rbenv or chruby.
```

---

## 🧪 Step 0 Verification: The Pre-Flight Diagnostics Gate

Once tools are installed, create your local configuration and run our diagnostic suite:

```bash
# 1. Copy environment template
cp .env.dist .env

# 2. Authenticate with Google Cloud
gcloud auth login
gcloud auth application-default login

# 3. Run the automated pre-flight diagnostics
just workshop-test
```

The diagnostic suite (`just workshop-test`) validates in real-time:
- 👤 **Identity & Admin Email**: Validates `ADMIN_EMAIL` in `.env`.
- ☁️ **GCP Project & Billing**: Validates `GOOGLE_CLOUD_PROJECT` and **mandatory active GCP billing** (`gcloud beta billing projects describe`).
- 🔐 **ADC Credentials**: Validates Application Default Credentials for Vertex AI without API keys.
- 🔑 **Rails Master Key**: Verifies local decryption keys.
- 🐤 **Storage Canary**: Checks for GCS canary asset readiness.

---

## 🗺️ Repository Anatomy & Local Command Center

Everything is orchestrated through [`justfile`](file:///justfile):

- 📄 [`justfile`](file:///justfile):
  - `just workshop-test`: Run pre-flight diagnostics suite 🧪
  - `just workshop-dev`: Run the interactive Codelab visualizer at `http://localhost:8080`
  - `just slides`: Run presentation slides at `http://localhost:8082`
  - `just dev`: Run local Rails 8 Puma server at `http://localhost:3000`
  - `just test`: Run fast automated unit & integration tests (< 5s)
  - `just compose-up`: Run multi-container local stack (app + PostgreSQL + Solid Queue + Mailpit)
- 📁 [`blog/`](file:///blog/): The core Rails 8 application codebase.
- 📁 [`workshop/`](file:///workshop/):
  - [`workshop/SKELETON.md`](file:///workshop/SKELETON.md): Master 8-step roadmap.
  - [`workshop/CODELAB.md`](file:///workshop/CODELAB.md): Extended narrative curriculum.
  - [`workshop/visualizer/`](file:///workshop/visualizer/): Isolated Sinatra Codelab viewer and GitHub Pages compiler.
- 📁 [`iac/`](file:///iac/): Infrastructure as Code (Terraform Cloud SQL, GCS, Cloud Run).

---

## 🚀 Ready to Begin Step 1?

Once `just workshop-test` outputs a clean green report, tell Google Antigravity:

> *"All pre-flight checks are green! Let's proceed to Step 1: configuring our .env and launching immutable Terraform infrastructure!"*

---

## 🐛 Found a Bug? Be Googley!

Be *googley*! If you find bugs of some sort, it would be nice for you to file a [GitHub Issue](https://github.com/palladius/rails8-app-on-gcp/issues/new), and maybe even a PR to this issue. Make sure to explain the context (at which workshop step, what you were told to do, ... and why/how it didn't work). The more detailed you'll be, the easier it will be for someone to fix the bug!

Enjoy the journey! 🚀

