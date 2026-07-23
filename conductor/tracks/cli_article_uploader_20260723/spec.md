# Specification: CLI Article Uploader (`bin/new_article.rb`)

## Overview
Create a Rails runner script to simplify the process of publishing articles to the blog directly from the command line. This allows users to test GCS uploads and create content without needing to start the local Rails server or interact with the web UI.

## Functional Requirements
- **CLI Interface**: Provide a script `bin/new_article.rb` that accepts:
  - `--article [path/to/file.md | -]` (Required): Path to the markdown file, or `-` to read from `stdin`.
  - `--image [path/to/image.png]` (Optional): Path to the image file to be attached as the cover image.
- **Title Extraction**:
  - The script will attempt to extract the title from the first `# Heading` in the provided markdown content.
  - If no heading is found, it will fallback to using the file's basename (excluding the extension) as the title. If read from stdin, it will use a generic default like "Untitled Article".
- **Image Attachment**:
  - The provided image (if any) will be attached exclusively to the `cover_image` attribute (targeting GCS).
  - If the `--image` flag provides a path that does not exist, the script will print a warning to `stderr`, skip the attachment, and proceed with creating the article anyway.
- **Publishing**: The article will be published immediately upon execution (no draft state).

## Non-Functional Requirements
- **Rails Runner**: The script must be executable via `bin/rails runner` or set up to initialize the Rails environment automatically if executed directly.
- **Standard I/O**: Must cleanly handle `stdin` streams to allow piping output from other tools directly into the blog.

## Acceptance Criteria
- User can run `bin/new_article.rb --article post.md --image hero.jpg` and successfully create a post.
- User can pipe content: `cat post.md | bin/new_article.rb --article -` and successfully create a post.
- Missing images trigger a warning but still create the text content.
- The title is properly inferred from the Markdown H1 or the filename.

## Out of Scope
- Local disk image attachments (`local_image`).
- Draft/Unpublished status (all posts are published instantly).
- YAML frontmatter parsing.
