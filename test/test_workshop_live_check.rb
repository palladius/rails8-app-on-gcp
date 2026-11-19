# frozen_string_literal: true

# Live checks for `just workshop-eval`: do the evals look at what is really deployed?
#
# Friction log FL014 (18 Nov 2026): `just workshop-eval 6` reported 11/11 while
# `gcloud run compose up` had failed and the service was still a single container.
# Friction log FL015: Deploy 3 "succeeded" with the previous step's configuration.
# Both would have been caught by one `gcloud run services describe` and one `/status.json`.
#
# The fixtures below have the shape of real `gcloud run services describe blog --format=json`
# output saved during FL014 and FL015 (names and values replaced).
require "minitest/autorun"
require "open3"
require "json"
require "yaml"
require "tmpdir"
require "fileutils"
require "stringio"
require_relative "../lib/workshop_eval/live_check"

class WorkshopLiveCheckTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  SA = "rails-cloudrun-sa@workshop-project.iam.gserviceaccount.com"
  COMPUTE_SA = "123456789012-compute@developer.gserviceaccount.com"
  STEP_6_EXPECT = {
    "ready" => true,
    "containers" => %w[web worker cloudsql-proxy],
    "service_account" => "rails-cloudrun-sa@",
    "secrets" => { "web" => %w[RAILS_MASTER_KEY DB_PASSWORD], "worker" => %w[RAILS_MASTER_KEY DB_PASSWORD] },
    "no_plain_env" => %w[DATABASE_URL DATABASE_QUEUE_URL DATABASE_CACHE_URL DATABASE_CABLE_URL DB_PASSWORD RAILS_MASTER_KEY],
    "status_json" => { "database_tier" => "cloud_sql", "storage_tier" => "gcs" }
  }.freeze

  def plain(name, value = "x") = { "name" => name, "value" => value }
  def secret(name, from) = { "name" => name, "valueFrom" => { "secretKeyRef" => { "key" => "latest", "name" => from } } }

  def service(containers:, service_account: SA, ready: "True")
    {
      "metadata" => { "name" => "blog" },
      "spec" => { "template" => { "spec" => { "serviceAccountName" => service_account, "containers" => containers } } },
      "status" => { "url" => "https://blog-example-ew.a.run.app", "conditions" => [{ "type" => "Ready", "status" => ready }] }
    }
  end

  def app_env_with_secrets
    [plain("DB_HOST", "cloudsql-proxy"), plain("ACTIVE_STORAGE_SERVICE", "google"),
     secret("RAILS_MASTER_KEY", "rails-master-key"), secret("DB_PASSWORD", "rails-db-password")]
  end

  # Deploy 4b done (FL015): what Step 6 is supposed to end with.
  def good_step_6_service
    service(containers: [
      { "name" => "cloudsql-proxy", "env" => [] },
      { "name" => "web", "env" => app_env_with_secrets },
      { "name" => "worker", "env" => app_env_with_secrets }
    ])
  end

  def good_status = { "database" => { "tier" => "cloud_sql" }, "storage" => { "tier" => "gcs" } }

  def problems(svc, status, expect = STEP_6_EXPECT)
    WorkshopEval::LiveCheck.evaluate(svc, status, expect)
  end

  # ---- the pure judgement -------------------------------------------------------------------

  def test_a_correct_step_6_deploy_has_no_problems
    assert_empty problems(good_step_6_service, good_status)
  end

  # FL014: compose up failed, the service is still the single container of Step 4.
  def test_a_single_container_service_is_reported_at_step_6
    svc = service(containers: [{ "name" => "blog-1", "env" => [plain("ACTIVE_STORAGE_SERVICE", "google")] }])
    found = problems(svc, { "database" => { "tier" => "local_sqlite" }, "storage" => { "tier" => "gcs" } })
    assert(found.any? { |p| p.include?("worker") && p.include?("cloudsql-proxy") }, found.inspect)
    assert(found.any? { |p| p.include?("database") && p.include?("local_sqlite") }, found.inspect)
  end

  # Codelab v2.4.0 as written: literal secrets and the Default Compute service account.
  def test_plain_text_secrets_and_the_wrong_service_account_are_reported
    leaky = [plain("DATABASE_URL", "postgresql://rails_user:REDACTED@cloudsql-proxy:5432/rails_production"),
             plain("RAILS_MASTER_KEY", "REDACTED")]
    svc = service(service_account: COMPUTE_SA, containers: [
      { "name" => "cloudsql-proxy", "env" => [] }, { "name" => "web", "env" => leaky }, { "name" => "worker", "env" => leaky }
    ])
    found = problems(svc, good_status)
    assert(found.any? { |p| p.include?("DATABASE_URL") && p.include?("plain") }, found.inspect)
    assert(found.any? { |p| p.include?("RAILS_MASTER_KEY") }, found.inspect)
    assert(found.any? { |p| p.include?("service account") && p.include?("rails-cloudrun-sa@") }, found.inspect)
    refute(found.join.include?("REDACTED"), "a live check must never print a secret value")
  end

  # Deploy 4a only: three containers, but the secrets are not mounted yet.
  def test_after_deploy_4a_only_the_missing_secrets_are_reported
    env = [plain("DB_HOST", "cloudsql-proxy"), plain("SECRET_KEY_BASE_DUMMY", "1")]
    svc = service(service_account: COMPUTE_SA, containers: [
      { "name" => "cloudsql-proxy", "env" => [] }, { "name" => "web", "env" => env }, { "name" => "worker", "env" => env }
    ])
    found = problems(svc, { "database" => { "tier" => "local_sqlite" }, "storage" => { "tier" => "gcs" } })
    assert(found.any? { |p| p.include?("web") && p.include?("DB_PASSWORD") && p.include?("Secret Manager") }, found.inspect)
    refute(found.any? { |p| p.include?("missing container") }, found.inspect)
  end

  # FL015: Step 4 deployed with the Step 3 configuration, so storage stayed on the local disk.
  def test_step_4_reports_storage_that_is_still_local
    expect = { "ready" => true, "status_json" => { "storage_tier" => "gcs" } }
    svc = service(containers: [{ "name" => "blog-1", "env" => [plain("ACTIVE_STORAGE_SERVICE", "google")] }])
    found = problems(svc, { "storage" => { "tier" => "local" } }, expect)
    assert_equal 1, found.size, found.inspect
    assert_includes found.first, "storage"
    assert_empty problems(svc, { "storage" => { "tier" => "gcs" } }, expect)
  end

  def test_a_service_that_is_not_ready_is_reported
    found = problems(service(containers: [{ "name" => "blog-1", "env" => [] }], ready: "False"), nil, { "ready" => true })
    assert(found.any? { |p| p.include?("not Ready") }, found.inspect)
  end

  # ---- talking to gcloud and curl -----------------------------------------------------------

  def with_fake_tools(gcloud_body:, curl_body: "echo '{}'")
    Dir.mktmpdir do |dir|
      { "gcloud" => gcloud_body, "curl" => curl_body }.each do |name, body|
        File.write(File.join(dir, name), "#!/bin/sh\n#{body}\n")
        File.chmod(0o755, File.join(dir, name))
      end
      yield dir
    end
  end

  def run_check(dir, extra_env = {}, expect: STEP_6_EXPECT)
    env = { "PATH" => "#{dir}:#{ENV['PATH']}", "GOOGLE_CLOUD_PROJECT" => "workshop-project", "FAKE_DIR" => dir }.merge(extra_env)
    out = StringIO.new
    result = WorkshopEval::LiveCheck.new(env: env, out: out).run("service" => "blog", "expect" => expect)
    [result, out.string]
  end

  def test_it_announces_each_remote_call_before_making_it_and_passes_on_a_good_deploy
    gcloud = "echo \"$CLOUDSDK_CORE_DISABLE_PROMPTS $*\" > \"$FAKE_DIR/gcloud.args\"\ncat <<'JSON'\n#{JSON.generate(good_step_6_service)}\nJSON"
    curl = "echo \"$*\" > \"$FAKE_DIR/curl.args\"\ncat <<'JSON'\n#{JSON.generate(good_status)}\nJSON"
    with_fake_tools(gcloud_body: gcloud, curl_body: curl) do |dir|
      result, printed = run_check(dir)
      assert_equal :passed, result.status, "#{result.problems.inspect}\n#{printed}"
      assert_match(/⏳ calling gcloud to read Cloud Run service 'blog'/, printed)
      assert_match(%r{⏳ fetching https://blog-example-ew\.a\.run\.app/status\.json}, printed)
      args = File.read(File.join(dir, "gcloud.args"))
      assert_match(/\A1 run services describe blog /, args, "gcloud must run with prompts disabled so it can never wait for an answer")
      assert_includes args, "--project workshop-project"
      assert_includes args, "--format=json"
      assert_includes File.read(File.join(dir, "curl.args")), "/status.json"
    end
  end

  def test_a_bad_deploy_is_a_warning_by_default_and_a_failure_in_strict_mode
    svc = service(containers: [{ "name" => "blog-1", "env" => [] }])
    gcloud = "cat <<'JSON'\n#{JSON.generate(svc)}\nJSON"
    with_fake_tools(gcloud_body: gcloud) do |dir|
      result, = run_check(dir)
      assert_equal :warning, result.status
      refute_empty result.problems
      strict, = run_check(dir, { "WORKSHOP_EVAL_LIVE" => "strict" })
      assert_equal :failed, strict.status
    end
  end

  def test_a_gcloud_that_hangs_is_cut_off_and_reported_not_waited_for
    with_fake_tools(gcloud_body: "sleep 30") do |dir|
      started = Time.now
      result, = run_check(dir, { "WORKSHOP_EVAL_LIVE_TIMEOUT" => "1" })
      assert_operator Time.now - started, :<, 10, "the check must give up after its timeout"
      assert_equal :warning, result.status
      assert(result.problems.any? { |p| p.include?("did not answer within 1s") }, result.problems.inspect)
    end
  end

  def test_a_gcloud_error_is_reported_with_its_own_words
    with_fake_tools(gcloud_body: "echo 'ERROR: (gcloud.run.services.describe) Cannot find service [blog]' >&2; exit 1") do |dir|
      result, = run_check(dir)
      assert_equal :warning, result.status
      assert(result.problems.any? { |p| p.include?("Cannot find service [blog]") }, result.problems.inspect)
    end
  end

  # /status.json is rate limited; a failed fetch must be reported as such, not as "storage is unknown".
  def test_an_unreadable_status_json_is_reported_as_unreadable
    gcloud = "cat <<'JSON'\n#{JSON.generate(good_step_6_service)}\nJSON"
    with_fake_tools(gcloud_body: gcloud, curl_body: "exit 22") do |dir|
      result, = run_check(dir)
      assert_equal :warning, result.status
      assert_equal 1, result.problems.size, result.problems.inspect
      assert_includes result.problems.first, "could not read https://blog-example-ew.a.run.app/status.json"
    end
  end

  def test_it_is_skipped_without_a_project_or_when_switched_off
    with_fake_tools(gcloud_body: "touch \"$FAKE_DIR/called\"") do |dir|
      result, printed = run_check(dir, { "GOOGLE_CLOUD_PROJECT" => "" })
      assert_equal :skipped, result.status
      refute_match(/⏳/, printed)
      off, = run_check(dir, { "WORKSHOP_EVAL_LIVE" => "off" })
      assert_equal :skipped, off.status
      refute File.exist?(File.join(dir, "called")), "gcloud must not be called when the check is skipped"
    end
  end

  # ---- the runner and the skeleton ----------------------------------------------------------

  def run_runner(dir, tools_dir, extra_env = {})
    env = { "PATH" => "#{tools_dir}:#{ENV['PATH']}", "GOOGLE_CLOUD_PROJECT" => "workshop-project", "FAKE_DIR" => tools_dir,
            "WORKSHOP_EVAL_LIVE" => nil }.merge(extra_env)
    Open3.capture3(env, "ruby", File.join(dir, "bin", "workshop_eval.rb"), "6")
  end

  def test_runner_shows_a_live_warning_without_failing_and_fails_in_strict_mode
    svc = service(containers: [{ "name" => "blog-1", "env" => [] }])
    with_fake_tools(gcloud_body: "cat <<'JSON'\n#{JSON.generate(svc)}\nJSON") do |tools|
      Dir.mktmpdir do |dir|
        FileUtils.mkdir_p([File.join(dir, "bin"), File.join(dir, "workshop")])
        FileUtils.cp(File.join(REPO_ROOT, "bin", "workshop_eval.rb"), File.join(dir, "bin"))
        FileUtils.cp_r(File.join(REPO_ROOT, "lib"), dir)
        File.write(File.join(dir, "workshop", "skeleton.yaml"), {
          "steps" => [{ "number" => 6, "title" => "Synthetic", "evals" => [
            { "id" => "ok", "type" => "ruby", "description" => "Passes", "code" => "1 + 1" },
            { "id" => "live", "type" => "live", "description" => "LIVE: deployed service", "service" => "blog", "expect" => STEP_6_EXPECT }
          ] }]
        }.to_yaml)

        stdout, _err, status = run_runner(dir, tools)
        assert_equal 0, status.exitstatus, stdout
        assert_includes stdout, "Evaluation Summary: 1/1 Passed, 0 Failed", "a live warning must not change the eval count:\n#{stdout}"
        assert_includes stdout, "⏳ calling gcloud"
        assert_match(/WARNING.*missing container/m, stdout)
        assert_match(/1 live check warning/, stdout)

        stdout, _err, status = run_runner(dir, tools, { "WORKSHOP_EVAL_LIVE" => "strict" })
        assert_equal 1, status.exitstatus, stdout
        assert_includes stdout, "Evaluation Summary: 1/2 Passed, 1 Failed"
      end
    end
  end

  def test_skeleton_has_a_live_check_for_steps_3_4_and_6
    steps = YAML.load_file(File.join(REPO_ROOT, "workshop", "skeleton.yaml"))["steps"]
    [3, 4, 6].each do |number|
      step = steps.find { |s| s["number"] == number }
      live = (step["evals"] || []).select { |e| e["type"] == "live" }
      assert_equal 1, live.size, "Step #{number} must have exactly one `live` eval"
      assert_equal "blog", live.first["service"]
      assert live.first["expect"].is_a?(Hash) && !live.first["expect"].empty?, "Step #{number} live eval needs an `expect`"
    end
    step6 = steps.find { |s| s["number"] == 6 }["evals"].find { |e| e["type"] == "live" }["expect"]
    assert_equal %w[web worker cloudsql-proxy].sort, step6["containers"].sort
    assert_equal %w[DB_PASSWORD RAILS_MASTER_KEY], step6.dig("secrets", "worker").sort
  end
end
