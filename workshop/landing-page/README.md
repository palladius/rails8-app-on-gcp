# 🧭 Workshop Landing Page & Antigravity Directive

> **🤖 Instruction for Google Antigravity:**
> You are acting as a patient, encouraging, and highly technical pair-programming tutor for this workshop.
> 
> **Supreme Rule of Engagement:**
> **DO NOT DO EVERYTHING FOR THE STUDENT.**
> - Guide them step by step.
> - Explain *why* things work the way they do (Ruby on Rails 8 concepts, GCP serverless patterns, security boundaries).
> - Give the student terminal commands and code snippets to run or inspect, and ask them to verify results before moving on.
> - When debugging, guide them to discover the error rather than blindly fixing it in the background.

---

## 👋 Welcome to the Rails 8 on Google Cloud Workshop!

Welcome! Whether you are a seasoned Ruby developer or a cloud engineer who has never touched Ruby before, this workshop is designed for you.

You are building a production-grade, cloud-native blog platform with **Ruby on Rails 8** and deploying it on **Google Cloud Platform (GCP)** using modern serverless infrastructure.

---

## 🗺️ Repository Anatomy

Everything you need is organized in this repository:

- 📄 [`justfile`](file:///justfile): **The command center.** Contains all recipes to build, run, test, and deploy.
  - `just slides`: Run the presentation deck at `http://localhost:8082`
  - `just workshop-dev`: Run the interactive step-by-step Codelab UI at `http://localhost:8080`
  - `just dev`: Run the local Rails 8 application at `http://localhost:3000`
  - `just test`: Run the test suite (fast & diagnostic)
  - `just compose-up`: Run multi-container local stack (app + PostgreSQL + Solid Queue)
- 📁 [`blog/`](file:///blog/): The core Rails 8 application codebase.
  - Built with modern Rails 8 features: Solid Queue (DB-backed background jobs), Propshaft, Importmaps, ActionText, and ActiveStorage.
- 📁 [`workshop/`](file:///workshop/): Workshop curriculum, steps, and interactive codelab viewer.
  - See [`workshop/CODELAB.md`](file:///workshop/CODELAB.md) for the complete curriculum.
  - Steps are grouped into Git branches: `workshop/step-1-local-baseline`, `workshop/step-2-docker-compose`, etc.
- 📁 [`iac/`](file:///iac/): Infrastructure as Code.
  - Cloud Run, Cloud SQL (PostgreSQL), Google Cloud Storage, Secret Manager, Cloud Build configurations.
- 📁 [`slides/`](file:///slides/): Marp presentation slides.

---

## 🚀 How to Begin (Step 0)

1. **Verify Your Local Setup:**
   Run the following in your terminal to see available commands:
   ```bash
   just
   ```
2. **Start the Workshop Guide:**
   Launch the workshop codelab server:
   ```bash
   just workshop-dev
   ```
   Then open [http://localhost:8080](http://localhost:8080) in your browser.

3. **Start the Rails App:**
   ```bash
   just dev
   ```
   Visit [http://localhost:3000](http://localhost:3000) to see your fresh Rails 8 application running locally on SQLite.

4. **Pair with Antigravity:**
   Ask Antigravity:
   > *"I have the app running on localhost. What is Step 1 of the workshop, and how does Rails 8 handle database storage locally vs in GCP?"*

Enjoy the journey! 🚀
