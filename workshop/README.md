## Note on this folder

We're going to grow the workshop inside this repo until we're ready.
When we're ready, Riccardo is going to port this to Google Codelabs.

* More user-facing details under `cfp/` 
* More process-details under `AGENTS.md`
## 📸 Declarative Screenshots

Screenshots for workshop steps and codelab walkthroughs are specified declaratively in `workshop/skeleton.yaml` and embedded in Markdown files (`CODELAB.md`) via HTML comments/directives:

```markdown
<!-- workshop-screenshot: id="step-2-home-ephemeral" -->
![Blog Homepage with Ephemeral DB Badge](assets/auto-screenshots/step-2-home-ephemeral.png)
```

Each screenshot references a Playwright runner script under `workshop/screenshots/` (e.g. `.playwright.js`).

### Commands

- **Validate all declarations and scripts:**
  ```bash
  just test-screenshots
  ```

- **Capture all screenshots:**
  ```bash
  just screenshots
  ```

- **Capture a specific step or screenshot:**
  ```bash
  just screenshots step-2
  just screenshots step-2-home-ephemeral
  ```
