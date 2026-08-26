# Step 1: The Local Baseline

Our starting point is a clean Rails 8 blog application running on SQLite with disk-based ActiveStorage.

### 1. Boot the App Locally

Run the setup commands to get the app running:

```bash
bundle install
bin/rails db:setup
bin/dev
```

Open `http://localhost:3000` in your browser. You can log in with the seeded credentials:
- **Email:** `riccardo@example.com`
- **Password:** `Ch4ng3m3!!1`

✨ **The Wow Moment:** The application is fully working locally in under 2 minutes! Try creating a new blog post and drag-and-drop an image directly into the ActionText / Trix rich-text editor. It uploads and renders instantly from your local disk storage.

### 2. Antigravity & Gemini Code Exploration

Let's use Antigravity / Gemini to inspect our application structure:
> *"Ask Gemini in Antigravity: Analyze our ActiveRecord models and generate a Mermaid diagram illustrating our Post, User, and ActiveStorage relationships."*

### 3. The Catch: Stateless Containers

Cloud Run containers are stateless and ephemeral. If we deploy our SQLite database and local `storage/` directory directly to Cloud Run, all posts and uploaded images will be permanently wiped out whenever a container scales to zero or restarts.

We need cloud-native persistence: **Cloud Storage** for assets, and **Cloud SQL** for our relational data.

