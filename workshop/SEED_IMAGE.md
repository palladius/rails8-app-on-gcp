# 🌱 Gem seeds: faster Cloud Builds for the blog image

For workshop leaders, and for anyone who wonders what `rails8-blog:gems` in their Artifact Registry is.

## Two seeds, two defaults

A *gem seed* is an image whose `/usr/local/bundle` already holds compiled gems. The `gems` stage of
`blog/Dockerfile` copies it in **before** `Gemfile`/`Gemfile.lock`, so `bundle install` only adds the
gems that are new or changed, and `bundle clean` drops the ones the lockfile no longer lists.

| | Project seed | Workshop seed |
|---|---|---|
| Image | `<region>-docker.pkg.dev/<project>/rails8-gcp-app/rails8-blog:gems` | `ghcr.io/palladius/rails8-blog-seed:gems` (+ `:buildcache`) |
| Owner | each project, in its own Artifact Registry | the workshop leader, public |
| Default | **always on** in Cloud Build | **opt-in**: `_WORKSHOP_SEED` (empty by default) |
| Written by | every build of that project | `.github/workflows/workshop-seed.yml` |
| Used when | the project has a valid `:gems` | the project has no valid `:gems` yet, i.e. its first build |

`blog/bin/cloudbuild-build-image`, shared by `cloudbuild.yaml` and `blog/cloudbuild-image.yaml`,
picks the seed in this order and logs its choice (`🌱 Gem seed: ...`):

1. the project's own `$IMAGE:gems`
2. `${_WORKSHOP_SEED}:gems`, only if `_WORKSHOP_SEED` is set
3. `base`: the empty stage, a full `bundle install`

Each candidate is checked with `docker buildx imagetools inspect` first (`FROM` on a missing ref is a
hard error), and skipped unless its `org.opencontainers.image.base.digest` label equals the
`RUBY_DIGEST` of the Dockerfile being built. A missing or stale seed never breaks a build: it only
makes it slower. The script also reads `${_WORKSHOP_SEED}:buildcache` (the `mode=max` layer cache,
which covers the apt layers) when it exists, and writes cache and seed **only** to the project's own
repository.

After an attendee's first build, their project has its own `:gems` and depends on nothing outside it.

A plain `docker build` in `blog/` never reads a seed: `ARG GEMS_SEED=base` keeps it a stock Rails 8
build that needs no registry beyond the Ruby base image.

### What it saves (measured)

Measured on a local Docker (buildx 0.39, `docker-container` builder, local registry), timing only the
`bundle install` step of the `gems` stage (123 gems). The build packages came from the full
`ruby:3.4.5` image because that sandbox could not reach the Debian mirrors. Not measured on Cloud Build yet.

| Build | `bundle install` step | Gems installed |
|---|---|---|
| No seed | 38.9 s | all |
| Own seed, nothing changed in `Gemfile.lock` | 5.3 s | 0 |
| Own seed, one gem added | 9.8 s | 1 |
| New project, workshop seed | 4.6 s | 0 |

The seeded steps are mostly `bootsnap precompile --gemfile`, plus fetching the gem index when a gem
is added.

## When a seed is valid

- **Same Ruby minor version.** Gems live under `ruby/3.4.0/`; after a minor bump that directory is
  ignored and everything is installed again: correct, but slow. The digest check below already skips
  such a seed.
- **Same base image digest.** Native extensions link against the base image's `libpq`, `libyaml` and
  the Ruby ABI. `blog/Dockerfile` pins `ruby:<RUBY_VERSION>-slim` by digest, and the gems stage
  stamps that digest into its labels; the script compares them.
- **No git gems.** Bundler keeps git checkouts in a different place; there are none today. Adding one
  works, it just is not seeded.

## Publishing the workshop seed (GitHub Actions → ghcr.io)

`.github/workflows/workshop-seed.yml` runs on every push to `main` that touches `blog/Gemfile`,
`blog/Gemfile.lock`, `blog/Dockerfile` or `.ruby-version`, and on demand (`workflow_dispatch`). It
runs the same `blog/bin/cloudbuild-build-image` as Cloud Build, with no app tags:

- the full `blog/` build only fills `ghcr.io/<owner>/rails8-blog-seed:buildcache`
  (`mode=max,image-manifest=true,oci-mediatypes=true`); **no app image is pushed**;
- `--target gems` is pushed as `:gems` and `:gems-lock-<first 12 hex of sha256(Gemfile.lock)>`;
- it is seeded from its own `:gems`, like any project.

It logs in with `GITHUB_TOKEN` (`packages: write`), and builds `linux/amd64` only: Cloud Build is the
only consumer of a seed, and it runs amd64. An arm64 seed would cost a QEMU build on every Gemfile
change and nobody would read it (a local `docker build` on Apple Silicon never uses a seed).

### One-time setup

1. **Actions → Workshop gem seed → Run workflow** on `main`.
2. On GitHub: **your profile (or org) → Packages → `rails8-blog-seed` → Package settings → Change
   visibility → Public.** New packages are private, and Cloud Build pulls anonymously.
3. Check anonymous pulls:
   ```bash
   docker logout ghcr.io
   docker pull ghcr.io/palladius/rails8-blog-seed:gems
   ```

If the owner is not `palladius`, change `WORKSHOP_SEED` in Steps 3, 4 and 6 of `workshop/CODELAB.md`
(and in `workshop/skeleton.yaml`, then `just build-skeleton`).

### Before each workshop

- The seed matches `main`:
  ```bash
  docker buildx imagetools inspect \
    "ghcr.io/palladius/rails8-blog-seed:gems-lock-$(sha256sum blog/Gemfile.lock | cut -c1-12)"
  ```
  Not found? Run the workflow.
- After a Ruby bump (or to pick up Debian security fixes), refresh the base digest in
  `blog/Dockerfile`, next to `RUBY_VERSION`:
  ```bash
  docker buildx imagetools inspect docker.io/library/ruby:3.4.5-slim   # the "Digest:" line
  ```
  The push to `main` rebuilds the seed. Until then, attendees get full installs, never broken builds.

### Without GitHub: a public Artifact Registry repository

Build in the leader's own project with `blog/cloudbuild-image.yaml` into a separate repository,
make it public, and point attendees at it:

```bash
gcloud artifacts repositories create rails8-blog-seed --repository-format=docker --location=europe-west1
gcloud artifacts repositories add-iam-policy-binding rails8-blog-seed --location=europe-west1 \
  --member=allUsers --role=roles/artifactregistry.reader
cd blog && gcloud builds submit --config cloudbuild-image.yaml \
  --substitutions=_AR_REGION=europe-west1,_AR_REPO=rails8-blog-seed
# attendees: export WORKSHOP_SEED=europe-west1-docker.pkg.dev/<leader-project>/rails8-blog-seed/rails8-blog
```

That build also pushes the app image (`:latest`) into the public repository. Caveats: the
*Domain restricted sharing* organization policy (`iam.allowedPolicyMemberDomains`) rejects `allUsers`,
and pulls from another region or from the internet are billed as egress to the leader's project.

## Starting a new app from this repository

Delete `.github/workflows/workshop-seed.yml` and the `_WORKSHOP_SEED` substitution in `cloudbuild.yaml`
and `blog/cloudbuild-image.yaml` (with its `WORKSHOP_SEED=...` in the build step). Keep the project
seed and the Dockerfile as they are: they depend on nothing outside your project.
