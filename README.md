# rails8-app-on-gcp

A golden Rails App optimized for GCP (ActiveStorage on GCS, docker-compose on Cloud Run, ...)

🟢 **Dev**: https://palladius-genai-rails-app-dev-272932496670.europe-west1.run.app/
🔴 **Prod**: https://palladius-genai-rails-app-prod-272932496670.europe-west1.run.app/

## 🚀 Quickstart: Starting the Apps & Services

You can run the project in three different local modes depending on your development focus:

### 1️⃣ Mode 1: Native Rails App (`just dev`)
Fastest feedback loop for application development using SQLite and Tailwind watcher.
```bash
# Install dependencies & prepare DB
just install

# Start local Rails development server (Puma on port 3000)
just dev
# (or: cd blog && bin/dev -p 3000)
```

### 2️⃣ Mode 2: Local Docker Compose Stack (`just compose-up`)
Full cloud-parity environment running PostgreSQL, background worker, Mailpit email catcher, and Adminer DB admin.
```bash
# Start all containers in detached mode
just compose-up
# (or: cd blog && docker compose up -d)

# Follow container logs
just compose-logs

# Stop containers
just compose-down
```

### 3️⃣ Mode 3: Local Workshop Codelab Server (`just workshop-dev`)
Sinatra-based interactive Codelab visualizer with hot-reloading (includes built-in document switcher for Codelab, Constitution, and Skeleton).
```bash
# Start the workshop server on port 8080
just workshop-dev
# (or: ruby workshop/visualizer/server.rb --port 8080)

# Direct document URLs:
# • Codelab:      http://localhost:8080/codelab
# • Constitution: http://localhost:8080/constitution
# • Skeleton:     http://localhost:8080/skeleton
# • A2UI JSON:    http://localhost:8080/a2ui
```

---

## 🧭 Localhost Services & Port Matrix

> 💡 **Fail-Fast Safety (Anti-POLA)**: Both **Native Dev** and **Docker Compose** intentionally target **Port 3000**. They are mutually exclusive, protecting you from ghost servers and ensuring [http://localhost:3000](http://localhost:3000) is *always* your Rails blog. Look at the **`RAILS8_ENV_LAUNCH_MODE`** telemetry badge in the footer to instantly see which runtime is responding!

| Mode / Environment | How to Start | Localhost Port(s) & URLs | Included Services |
| :--- | :--- | :--- | :--- |
| 🚀 **1. Native Rails App** | `just dev` | • [http://localhost:3000](http://localhost:3000) | Rails 8 Puma Server + Tailwind CSS Watcher (SQLite) |
| 🐳 **2. Docker Compose** | `just compose-up` | • [http://localhost:3000](http://localhost:3000)<br>• [http://localhost:8025](http://localhost:8025)<br>• [http://localhost:8081](http://localhost:8081)<br>• `localhost:5432` | • Rails 8 Web Server (`:3000`)<br>• Mailpit Email UI (`:8025`, SMTP `:1025`)<br>• Adminer DB GUI (`:8081`)<br>• PostgreSQL 16 DB (`:5432`)<br>• Solid Queue Worker (Background) |
| 📖 **3. Workshop Web UI** | `just workshop-dev` | • [http://localhost:8080](http://localhost:8080)<br>• [http://localhost:8080/constitution](http://localhost:8080/constitution)<br>• [http://localhost:8080/skeleton](http://localhost:8080/skeleton)<br>• [http://localhost:8080/a2ui](http://localhost:8080/a2ui) | • Interactive Codelab Visualizer (`CODELAB.md`)<br>• Untouchable Constitution<br>• Workshop Skeleton<br>• A2UI JSON API |

## 📖 Workshop

The workshop is published on GitHub Pages:

* 🌐 **Live Codelab:** [https://palladius.github.io/rails8-app-on-gcp/](https://palladius.github.io/rails8-app-on-gcp/) (official Google Codelab visualizer)
* 📜 **Constitution:** [https://palladius.github.io/rails8-app-on-gcp/constitution.html](https://palladius.github.io/rails8-app-on-gcp/constitution.html)
* 🦴 **Skeleton:** [https://palladius.github.io/rails8-app-on-gcp/skeleton.html](https://palladius.github.io/rails8-app-on-gcp/skeleton.html)

![Workshop Preview](assets/workshop_preview.png)
