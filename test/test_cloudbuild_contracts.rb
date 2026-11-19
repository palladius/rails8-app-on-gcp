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

  def setup
    @cloudbuild = YAML.load_file(CLOUDBUILD_PATH)
    @build_script = @cloudbuild.fetch("steps").map { |step| step.fetch("args", []).join(" ") }.join("\n")
  end

  # A plain `--cache-from <image>` never hits under BuildKit (no cache metadata),
  # and inline cache leaves out the `build` stage. Only mode=max keeps the gems.
  def test_build_exports_and_imports_a_registry_cache_of_every_stage
    assert_match(/--cache-to "?type=registry,ref=[^ ]*:buildcache,mode=max/, @build_script)
    assert_match(/--cache-from "?type=registry,ref=[^ ]*:buildcache/, @build_script)
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
    assert_match(/--cache-to "?type=registry,ref=\$\$IMAGE:buildcache,mode=max/, script)
    assert_match(/--cache-from "?type=registry,ref=\$\$IMAGE:buildcache/, script)
    assert_match(/buildx create[^\n]*--driver=docker-container/, script)
    assert_match(/--push \.$/, script, "the image build runs from blog/, so its context is .")
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

  def test_skeleton_mirrors_the_build_once_flow
    [3, 4, 6].each do |number|
      assert_includes skeleton_step(number), BUILD_COMMAND, "SKELETON.md Step #{number} must build with the cache"
    end
    [3, 4].each do |number|
      refute_includes skeleton_step(number), "--source", "SKELETON.md Step #{number} must not deploy with --source"
    end
  end
end
