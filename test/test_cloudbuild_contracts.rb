# frozen_string_literal: true

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require "minitest/autorun"
require "yaml"

# Every Cloud Build runs on a fresh VM, so the layer cache must live in Artifact Registry
# and must cover the `build` stage, where `bundle install` runs.
# Measurements: https://github.com/palladius/rails8-app-on-gcp/issues/217 (slow codelab builds)
class CloudbuildContractsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  CLOUDBUILD_PATH = File.join(REPO_ROOT, "cloudbuild.yaml")
  SUBMIT_PATH = File.join(REPO_ROOT, "bin", "cloudbuild-submit")
  IMAGE_SCRIPT_PATH = File.join(REPO_ROOT, "blog", "bin", "cloudbuild-build-image")

  def setup
    @cloudbuild = YAML.load_file(CLOUDBUILD_PATH)
    @build_script = @cloudbuild.fetch("steps").map { |step| step.fetch("args", []).join(" ") }.join("\n")
  end

  # A plain `--cache-from <image>` never hits under BuildKit (no cache metadata),
  # and inline cache leaves out the `build` stage. Only mode=max keeps the gems.
  # The buildx calls live in the script shared with blog/cloudbuild-image.yaml.
  def test_build_exports_and_imports_a_registry_cache_of_every_stage
    assert_match(%r{bash blog/bin/cloudbuild-build-image "\$\$IMAGE" blog }, @build_script)
    image_script = File.read(IMAGE_SCRIPT_PATH)
    assert_match(/--cache-to "?type=registry,ref=[^ ]*:buildcache,mode=max/, image_script)
    assert_match(/--cache-from "?type=registry,ref=[^ ]*:buildcache/, image_script)
  end

  def test_build_uses_a_builder_that_can_export_a_registry_cache
    assert_match(/buildx create[^\n]*--driver=docker-container/, @build_script)
  end

  # buildx pushes from its own builder; an `images:` list would make Cloud Build push
  # from the local daemon, which never holds the image.
  def test_cloudbuild_has_no_images_section
    refute @cloudbuild.key?("images"), "cloudbuild.yaml must not list images: buildx pushes them itself"
  end

  # Substitutions are stored in the build record in plain text.
  def test_no_secret_travels_as_a_substitution
    secret_keys = @cloudbuild.fetch("substitutions").keys.grep(/MASTER_KEY|DATABASE_URL|PASSWORD|SECRET/)
    assert_empty secret_keys, "cloudbuild.yaml must not declare secret substitutions"
    refute_match(/_(RAILS_MASTER_KEY|DATABASE_URL)=/, File.read(SUBMIT_PATH),
                 "bin/cloudbuild-submit must not pass secrets as substitutions")
  end

  # Cloud Build hands SHORT_SHA and COMMIT_SHA to a step as substitutions, not as
  # environment variables, so `$${COMMIT_SHA}` is an unset variable under `set -u`.
  def test_commit_sha_comes_from_the_substitution
    refute_match(/\$\$\{(COMMIT_SHA|SHORT_SHA:-\$)/, @build_script)
    assert_match(/SHORT_SHA="\$SHORT_SHA"/, @build_script)
  end

  def test_default_service_name_belongs_to_this_project
    assert_equal "blog", @cloudbuild.dig("substitutions", "_APP_NAME")
  end
end

# The codelab builds once with the cache and deploys the pushed image: a `--source` deploy
# rebuilds from scratch every time, and `compose up` with `build:` builds web and worker.
class CodelabImageReuseContractsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  IMAGE_BUILD_PATH = File.join(REPO_ROOT, "blog", "cloudbuild-image.yaml")
  COMPOSE_PROD_PATH = File.join(REPO_ROOT, "blog", "compose.prod.yaml")
  BUILD_COMMAND = "gcloud builds submit --config cloudbuild-image.yaml"

  def codelab_step(number)
    File.read(File.join(REPO_ROOT, "workshop", "CODELAB.md"))[/^## Step #{number}:.*?(?=^## Step )/m]
  end

  def skeleton_step(number)
    File.read(File.join(REPO_ROOT, "workshop", "SKELETON.md"))[/^### Step #{number}:.*?(?=^### Step )/m]
  end

  def test_image_build_shares_the_registry_cache_of_the_ci_build
    script = YAML.load_file(IMAGE_BUILD_PATH).fetch("steps").map { |step| step.fetch("args", []).join(" ") }.join("\n")
    assert_match(%r{IMAGE="[^"]*/rails8-blog"}, script, "same image name as cloudbuild.yaml, so both share one cache")
    image_script = File.read(File.join(REPO_ROOT, "blog", "bin", "cloudbuild-build-image"))
    assert_match(/--cache-to "?type=registry,ref=\$IMAGE:buildcache,mode=max/, image_script)
    assert_match(/--cache-from "?type=registry,ref=\$IMAGE:buildcache/, image_script)
    assert_match(/buildx create[^\n]*--driver=docker-container/, script)
    assert_match(%r{bash bin/cloudbuild-build-image "\$\$IMAGE" \. latest$}, script,
                 "the image build runs from blog/, so its context is .")
  end

  def test_compose_prod_deploys_the_prebuilt_image
    services = YAML.load_file(COMPOSE_PROD_PATH).fetch("services")
    %w[web worker].each do |name|
      refute services[name].key?("build"), "compose.prod.yaml #{name} must not build: compose up would build it again"
      assert_equal "${BLOG_IMAGE}", services[name]["image"]
    end
  end

  def test_codelab_deploys_build_once_and_reuse_the_image
    [3, 4].each do |number|
      step = codelab_step(number)
      refute_match(/gcloud run deploy blog\s*\\\s*\n\s*--source/, step, "Step #{number} must not deploy with --source")
      assert_includes step, BUILD_COMMAND, "Step #{number} must build with the cache"
      assert_match(/gcloud run deploy blog\s*\\\s*\n\s*--image \$BLOG_IMAGE/, step)
    end
    step6 = codelab_step(6)
    assert_operator step6.index(BUILD_COMMAND).to_i, :<, step6.index("gcloud run compose up").to_i,
                    "Step 6 must build the gold image before compose up"
  end

  SEED_SUBSTITUTION = "--substitutions=_AR_REGION=$GOOGLE_CLOUD_REGION,_WORKSHOP_SEED=$WORKSHOP_SEED"
  SEED_EXPORT = "export WORKSHOP_SEED=ghcr.io/palladius/rails8-blog-seed"

  # Opt-in workshop seed: one export next to BLOG_IMAGE, one substitution on every image build.
  def test_codelab_builds_pass_the_workshop_seed
    [3, 4, 6].each do |number|
      [["CODELAB.md", codelab_step(number)], ["SKELETON.md", skeleton_step(number)]].each do |file, step|
        assert_includes step, "#{BUILD_COMMAND} #{SEED_SUBSTITUTION}", "#{file} Step #{number} must pass _WORKSHOP_SEED"
      end
      step = codelab_step(number)
      assert_operator step.index(SEED_EXPORT).to_i, :>, step.index("export BLOG_IMAGE=").to_i,
                      "CODELAB.md Step #{number} must export WORKSHOP_SEED next to BLOG_IMAGE"
    end
    [3, 6].each { |number| assert_includes skeleton_step(number), SEED_EXPORT, "SKELETON.md Step #{number}" }
    assert_includes codelab_step(3), "workshop/SEED_IMAGE.md", "Step 3 troubleshooting must link the seed guide"
  end

  def test_skeleton_mirrors_the_build_once_flow
    [3, 4, 6].each do |number|
      assert_includes skeleton_step(number), BUILD_COMMAND, "SKELETON.md Step #{number} must build with the cache"
    end
    [3, 4].each do |number|
      refute_includes skeleton_step(number), "--source", "SKELETON.md Step #{number} must not deploy with --source"
    end
  end
end

# The gem seed: `bundle install` starts from a prebuilt /usr/local/bundle and installs only the delta.
# A plain `docker build` in blog/ must stay seed-free, like a stock Rails 8 Dockerfile.
class DockerfileGemSeedContractsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)

  def setup
    @dockerfile = File.read(File.join(REPO_ROOT, "blog", "Dockerfile"))
  end

  def stage(name)
    @dockerfile[/^FROM [^\n]* AS #{name}\n.*?(?=^FROM )/m] or flunk "blog/Dockerfile has no #{name} stage"
  end

  def test_default_seed_is_the_empty_base_stage
    assert_match(/^ARG GEMS_SEED=base$/, @dockerfile)
    assert_match(/^FROM \$\{GEMS_SEED\} AS gem-seed$/, @dockerfile)
  end

  # A seed or a shared layer cache is only valid on the exact base bytes it was built on.
  def test_base_image_is_pinned_by_digest
    digest = @dockerfile[/^ARG RUBY_DIGEST=(sha256:[0-9a-f]{64})$/, 1]
    assert digest, "blog/Dockerfile must pin the Ruby base image by digest"
    assert_match(/^FROM docker\.io\/library\/ruby:\$RUBY_VERSION-slim@\$RUBY_DIGEST AS base$/, @dockerfile)
    assert_equal File.read(File.join(REPO_ROOT, "blog", ".ruby-version")).strip,
                 @dockerfile[/^ARG RUBY_VERSION=(\S+)$/, 1]
  end

  # vendor/ is copied by `COPY . .` anyway; copying it before Gemfile ties the gem layer to importmap pins.
  def test_no_vendor_copy_before_the_gemfile
    refute_match(/^COPY vendor/, @dockerfile)
  end

  def test_production_image_skips_development_and_test_gems
    assert_includes @dockerfile, 'BUNDLE_WITHOUT="development:test"'
  end

  def test_gems_stage_order_keeps_shareable_layers_first
    gems = stage("gems")
    apt = gems.index("apt-get install").to_i
    seed = gems.index("COPY --from=gem-seed /usr/local/bundle /usr/local/bundle")
    gemfile = gems.index("COPY Gemfile Gemfile.lock ./")
    install = gems.index("RUN bundle install")
    clean = gems.index("bundle clean --force")
    assert seed && gemfile && install && clean, "gems stage must copy the seed, the Gemfile, install and clean"
    assert_operator apt, :>, 0, "build packages are installed in the gems stage"
    assert_operator apt, :<, seed, "apt install must come before the seed copy, so its layer stays shareable"
    assert_operator seed, :<, gemfile, "the seed copy must not depend on Gemfile.lock"
    assert_operator install, :<, clean, "bundle clean must run after bundle install"
  end

  def test_build_stage_starts_from_the_gems_stage
    assert_match(/^FROM gems AS build$/, @dockerfile)
  end
end

# Seed selection and the build live in one script, shared by both Cloud Build configs.
class CloudbuildGemSeedScriptContractsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  SCRIPT_PATH = File.join(REPO_ROOT, "blog", "bin", "cloudbuild-build-image")
  CONFIGS = {
    "cloudbuild.yaml" => %r{bash blog/bin/cloudbuild-build-image "\$\$IMAGE" blog },
    "blog/cloudbuild-image.yaml" => %r{bash bin/cloudbuild-build-image "\$\$IMAGE" \. }
  }.freeze

  def setup
    @script = File.read(SCRIPT_PATH)
  end

  def test_both_configs_build_through_the_shared_script
    CONFIGS.each do |path, call|
      config = YAML.load_file(File.join(REPO_ROOT, path))
      steps = config.fetch("steps").map { |step| step.fetch("args", []).join(" ") }.join("\n")
      assert_match call, steps, "#{path} must build with the shared script"
      assert_includes steps, 'WORKSHOP_SEED="${_WORKSHOP_SEED}"', "#{path} must hand _WORKSHOP_SEED to the script"
      refute_match(/docker buildx build/, steps, "#{path} must not build outside the shared script")
    end
  end

  # Opt-in: without it, a project depends on nothing outside itself.
  def test_workshop_seed_defaults_to_empty
    CONFIGS.each_key do |path|
      assert_equal "", YAML.load_file(File.join(REPO_ROOT, path)).dig("substitutions", "_WORKSHOP_SEED"), path
    end
  end

  def test_script_is_strict_bash
    assert @script.start_with?("#!/usr/bin/env bash\n")
    assert_includes @script, "set -euo pipefail"
    assert File.executable?(SCRIPT_PATH), "blog/bin/cloudbuild-build-image must be executable"
  end

  # `FROM` on a missing ref fails the build: own seed, then the workshop seed, then the empty base stage.
  def test_seed_order_is_own_then_workshop_then_base
    base = @script.index("GEMS_SEED=base")
    own = @script.index('CANDIDATES=("$IMAGE:gems")')
    workshop = @script.index('[ -n "$WORKSHOP_SEED" ] && CANDIDATES+=("$WORKSHOP_SEED:gems")')
    assert base && own && workshop, "the script must default to base and try $IMAGE:gems, then $WORKSHOP_SEED:gems"
    assert_operator base, :<, own
    assert_operator own, :<, workshop
    assert_match(/for candidate in "\$\{CANDIDATES\[@\]\}"; do\n\s+problem="\$\(seed_problem "\$candidate"\)"/, @script)
    assert_match(/seed_problem\(\) \{\n.*docker buildx imagetools inspect [^\n]*"\$1"/m, @script)
    assert_includes @script, 'echo "🌱 Gem seed: $GEMS_SEED"', "the chosen seed must be logged"
  end

  # A seed is only valid on the base bytes it was built on (native extensions, Ruby ABI).
  def test_seed_must_match_the_base_digest_of_the_dockerfile
    assert_includes @script, "s/^ARG RUBY_DIGEST=//p"
    assert_match(/grep -Eq "\\"org\.opencontainers\.image\.base\.digest\\": \*\\"\$BASE_DIGEST\\""/, @script)
    dockerfile = File.read(File.join(REPO_ROOT, "blog", "Dockerfile"))
    gems_stage = dockerfile[/^FROM base AS gems\n.*?(?=^FROM )/m]
    assert_includes gems_stage, 'org.opencontainers.image.base.digest="${RUBY_DIGEST}"'
  end

  def test_workshop_layer_cache_is_read_only_when_it_exists
    assert_match(/if docker buildx imagetools inspect "\$WORKSHOP_SEED:buildcache"[^\n]*; then\n\s+CACHE_FROM\+=\(--cache-from "type=registry,ref=\$WORKSHOP_SEED:buildcache"\)/, @script)
  end

  # Writing the workshop repository from an attendee's build would fail (no access) or poison it.
  def test_cache_and_images_are_written_only_to_the_project
    cache_to = @script.scan(/--cache-to "([^"]*)"/).flatten
    assert_equal ["type=registry,ref=$IMAGE:buildcache,mode=max,image-manifest=true,oci-mediatypes=true"], cache_to
    @script.scan(/-t "([^"]*)"/).flatten.each do |tag|
      assert tag.start_with?("$IMAGE:"), "the script must only push to $IMAGE, not #{tag}"
    end
  end

  def test_gems_seed_is_pushed_after_the_app_build
    app_build = @script.index("--cache-to ")
    assert_includes @script, 'SEED_TAGS=(-t "$IMAGE:gems")'
    seed_push = @script.index('--target gems "${SEED_TAGS[@]}"')
    assert seed_push, "the script must push the gems stage as $IMAGE:gems"
    assert_operator app_build, :<, seed_push
    seed_build = @script[@script.rindex("docker buildx build", seed_push)..]
    assert_includes seed_build, '--build-arg "GEMS_SEED=$GEMS_SEED"', "the seed build must use the same seed"
    refute_includes seed_build, "$WORKSHOP_SEED", "the seed build reads only the project's own cache"
  end

  def test_script_stays_out_of_the_image
    assert_includes File.read(File.join(REPO_ROOT, "blog", ".dockerignore")).lines.map(&:strip), "/bin/cloudbuild-build-image"
  end
end

# The public workshop seed: published by GitHub Actions, and it must never publish the app itself.
class WorkshopSeedWorkflowContractsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  WORKFLOW_PATH = File.join(REPO_ROOT, ".github", "workflows", "workshop-seed.yml")

  def setup
    @workflow = YAML.load_file(WORKFLOW_PATH)
    @run = @workflow.dig("jobs", "seed", "steps").map { |step| step["run"].to_s }.join("\n")
  end

  def test_triggers_on_gem_and_base_changes_and_on_demand
    on = @workflow["on"] || @workflow[true] # YAML 1.1 reads a bare `on` as true
    assert_equal ["main"], on.dig("push", "branches")
    assert_equal %w[blog/Gemfile blog/Gemfile.lock blog/Dockerfile .ruby-version].sort, on.dig("push", "paths").sort
    assert on.key?("workflow_dispatch")
  end

  def test_pushes_to_ghcr_with_the_workflow_token
    assert_equal "write", @workflow.dig("permissions", "packages")
    uses = @workflow.dig("jobs", "seed", "steps").map { |step| step["uses"].to_s }
    assert uses.any? { |u| u.start_with?("docker/setup-buildx-action@") }
    login = @workflow.dig("jobs", "seed", "steps").find { |step| step["uses"].to_s.start_with?("docker/login-action@") }
    assert_equal "ghcr.io", login.dig("with", "registry")
    assert_equal "${{ secrets.GITHUB_TOKEN }}", login.dig("with", "password")
  end

  # No tag between the context and `--`: the app image only fills :buildcache.
  def test_pushes_only_gems_and_buildcache_never_an_app_image
    assert_match(%r{bash blog/bin/cloudbuild-build-image "\$SEED_REPO" blog -- --platform linux/amd64}, @run)
    assert_match(/SEED_EXTRA_TAGS="gems-lock-\$LOCK_HASH"/, @run)
    assert_match(/LOCK_HASH="\$\(sha256sum blog\/Gemfile\.lock \| cut -c1-12\)"/, @run)
    refute_match(/docker (buildx build|push)/, @run, "the workflow must build only through the shared script")
    script = File.read(File.join(REPO_ROOT, "blog", "bin", "cloudbuild-build-image"))
    assert_match(/APP_OUTPUT=\(--output type=cacheonly\)/, script, "without app tags the script must not push an app image")
  end

  def test_leader_runbook_is_linked
    assert File.exist?(File.join(REPO_ROOT, "workshop", "SEED_IMAGE.md"))
    assert_includes File.read(File.join(REPO_ROOT, "workshop", "README.md")), "SEED_IMAGE.md"
  end
end
