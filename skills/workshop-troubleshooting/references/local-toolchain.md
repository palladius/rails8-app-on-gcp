# 🛠️ Local Development & Toolchain Friction

This guide covers common issues when working locally with Git worktrees, Bundler, Docker Compose, and the `just` command runner.

---

## 🔴 `Bundler::GemNotFound` during `just workshop-uat` in Git Worktree

### Symptom
Running `just workshop-uat <step>` fails with:
`Could not find rails-8.1.3 in locally installed gems (Bundler::GemNotFound)`

### Cause
Git worktrees are isolated working trees that do not automatically share the local `.bundle/` config or `vendor/bundle/` from the main repository.

### Fix
Ensure the worktree points to the shared user gem repository or run bundle install:
```bash
cd blog && bundle install
```

---

## 🔴 Docker Compose Port Collisions (Port 5432 or 8025 in Use)

### Symptom
`just compose-up` fails with:
`Error response from daemon: Ports are not available: listen tcp 0.0.0.0:5432: bind: address already in use`

### Cause
A local system PostgreSQL service or Mailpit instance is already running on the host machine.

### Fix
Stop local system PostgreSQL or free up port 5432:
```bash
# On Linux / Debian:
sudo systemctl stop postgresql

# Or check what process is holding port 5432:
lsof -i :5432
```

---

## 🔴 `just` Command Fails with Exit Code

### Symptom
`just test` or `just dev` exits immediately with an error.

### Cause
Missing prerequisite CLI tools or environment variables in `.env`.

### Fix
Run the automated diagnostic suite to detect missing tools:
```bash
just workshop-test
```
