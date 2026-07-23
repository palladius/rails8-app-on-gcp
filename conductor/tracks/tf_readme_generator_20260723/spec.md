# Specification: Terraform Markdown Generator & Article Updater

## Overview
Generate a dynamic, beautifully formatted Markdown file (`iac/TF_README.md`) directly from Terraform during `terraform apply`. This file will contain clickable links to the Google Cloud Console for all provisioned resources (GCS buckets, Secret Manager secrets, Cloud SQL instances, etc.). Furthermore, we will update the CLI uploader script (`bin/new_article.rb`) to find a "sticky" post by title (e.g., "Infrastructure State") so that running the script updates the existing post and appends a literal Rails `Comment` recording the execution event, rather than creating duplicate posts.

## Functional Requirements
- **Terraform Markdown Generation**:
  - Use a Terraform `local_file` resource and a `.tftpl` template to generate `iac/TF_README.md`.
  - The markdown must include an ordered bulleted list of all key GCP resources with deep links to their respective Google Cloud Console pages (e.g., `https://console.cloud.google.com/storage/browser/[BUCKET_NAME]`).
- **CLI Uploader (`bin/new_article.rb`) Enhancements**:
  - Modify the script to search for an existing `Post` matching the exact title extracted from the markdown.
  - If a matching post exists, **update** its content instead of creating a new record.
  - If a matching post exists, automatically create a new `Comment` attached to the `Post` to serve as an audit log of the execution (e.g., "Updated on [Timestamp]").
  - If no matching post exists, create it as usual.

## Non-Functional Requirements
- **Idempotency**: The `terraform apply` step should cleanly overwrite the local Markdown file. The Rails CLI script should safely update the same post on subsequent runs.
- **Aesthetics**: The Markdown template must be visually pleasing with appropriate headers, emojis, and valid markdown links.

## Acceptance Criteria
- Running `terraform apply` creates/updates `iac/TF_README.md` with accurate, clickable GCP console links based on actual provisioned outputs.
- Running `bin/new_article.rb --article iac/TF_README.md` creates a new post on the first run.
- Running the script a second time updates the body of the existing post and adds a new `Comment` indicating it was updated.

## Out of Scope
- Actually writing the entirety of the Terraform module (we are just adding the `local_file` output generator to whatever currently exists or will exist).
