# Product Guidelines

## 1. UI & Aesthetics (L'occhio vuole la sua parte!)
- **Clean & Unbreakable Base:** Rely on standard, robust CSS/JS that doesn't break across different environments.
- **Googley / Gemini Theme:** Incorporate a modern, premium aesthetic inspired by Google/Gemini branding. Use soft colors, glassmorphism (transparency), nice cards, and smooth transitions. The interface should feel incredibly premium but structurally simple.

## 2. Developer Experience (DX) & Code Style
- **Friendly & Instructional:** Since this is a workshop codebase, comments are a first-class feature. Explain the "why" directly in the codebase (e.g., above complex GCP configurations or Rails 8 solid component setups). 
- **Readability First:** Favor explicit, readable code over overly clever or concise Ruby tricks. Workshop attendees should be able to parse the logic instantly.

## 3. Error Handling Philosophy
- **Fail Fast & Loud:** In an educational context, silent failures are the enemy. If a critical environment variable is missing (e.g., `GCP_PROJECT_ID` or `DATABASE_URL`), the app should crash immediately with a loud, descriptive error message explaining exactly what the attendee missed. 
- **No Graceful Degradation for Infrastructure:** Do not fall back to local disk if Cloud Storage fails in production, so the user knows exactly when they have successfully wired up GCP.
