# Implementation Plan: Declarative Workshop Skeleton in YAML with Hybrid & LLM EVALs

## Phase 1: Skeleton YAML Architecture & Schema Definition
- [ ] Task: Create `workshop/skeleton.yaml` with schema definition and full 8-step curriculum
  - [ ] Define Steps 0 through 8 with `title`, `description`, `pseudocode`, `prerequisites`, `postrequisites`
  - [ ] Add `evals` with mixed types: `shell`, `ruby`, and `llm` (with structured `{return, comment, error_message}` output)
- [ ] Task: Phase Verification & Checkpoint (Validate YAML syntax and readability)

## Phase 2: Markdown Compiler (`build_skeleton.rb`)
- [ ] Task: Implement `workshop/visualizer/build_skeleton.rb`
  - [ ] Parse `workshop/skeleton.yaml` and render `workshop/SKELETON.md`
  - [ ] Wire recipe into `justfile`: `just build-skeleton`
  - [ ] Hook into `just build-ghpages`
- [ ] Task: Phase Verification & Checkpoint (Verify generated SKELETON.md matches expected layout)

## Phase 3: Evaluation Engine (`bin/workshop_eval.rb`)
- [ ] Task: Implement `bin/workshop_eval.rb`
  - [ ] Add execution handler for `type: shell`
  - [ ] Add execution handler for `type: ruby`
  - [ ] Add execution handler for `type: llm` with structured JSON contract
  - [ ] Add recipe to `justfile`: `just workshop-eval [step="all"]`
- [ ] Task: Phase Verification & Checkpoint (Run `just workshop-eval 0` and verify green output)
