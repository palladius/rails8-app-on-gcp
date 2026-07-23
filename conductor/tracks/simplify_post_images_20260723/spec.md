# Specification: Simplify Post Images (`single_cover_image`)

## Overview
Currently, the `Post` model supports two image attachments: `cover_image` (originally targeted for GCS) and `local_image` (targeted for local disk). To simplify the application and streamline the workshop experience, we will refactor the `Post` model to only use a single `cover_image`. This image will use the default ActiveStorage service based on the environment (e.g., local in development initially, moving to GCS later in the workshop).

## Functional Requirements
- **Data Migration**: Create a Rails migration or Rake task (or handle it in `db:seed`) to migrate any existing `local_image` attachments to `cover_image` to ensure no data is lost during the refactor. (Alternatively, just dropping the attachments is acceptable for development).
- **Model Simplification**: Remove the `has_one_attached :local_image` declaration from the `Post` model.
- **Controller Updates**: Update `PostsController` strong parameters (`post_params`) to remove `:local_image`.
- **View Updates**: 
  - Remove the `local_image` file upload field from `app/views/posts/_form.html.erb`.
  - Update `app/views/posts/index.html.erb` and `show.html.erb` to only display the `cover_image` and remove any UI elements or image counts specific to `local_image`.

## Acceptance Criteria
- The `Post` model only has one attachment: `cover_image`.
- Existing posts that previously had a `local_image` are handled without crashing the app.
- The UI (forms, lists, and show pages) only references and displays the `cover_image`.
- The application runs without errors and all tests pass.

## Out of Scope
- Configuring the GCS bucket or modifying `config/storage.yml` (the `cover_image` will continue to use whatever service it is currently configured for).
