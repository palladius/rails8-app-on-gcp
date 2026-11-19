# frozen_string_literal: true

require "json"

module WorkshopEval
  # A `live` eval asks Google Cloud what is really deployed, instead of reading files in the
  # repository. One `gcloud run services describe` and, when the step asks for it, one
  # `GET <service url>/status.json`.
  #
  # It announces every remote call before making it, runs gcloud with prompts disabled and
  # gives up after a timeout, so it can never sit there waiting for an answer.
  #
  # Modes (environment variable WORKSHOP_EVAL_LIVE):
  #   warn   (default) problems are shown as a warning and do not fail the eval run
  #   strict           problems fail the eval run (use this in friction logs and CI)
  #   off              no remote call at all
  class LiveCheck
    Result = Struct.new(:status, :problems, :note)

    DEFAULT_TIMEOUT = 30

    # Pure judgement: compares what is deployed with what the step expects.
    # service: parsed `gcloud run services describe --format=json`; status: parsed /status.json or nil.
    # Returns a list of human-readable problems. Never includes an environment variable's value.
    def self.evaluate(service, status, expect)
      problems = []
      spec = service.dig("spec", "template", "spec") || {}
      containers = Array(spec["containers"])
      by_name = containers.to_h { |c| [c["name"].to_s, Array(c["env"])] }

      if expect["ready"]
        ready = Array(service.dig("status", "conditions")).find { |c| c["type"] == "Ready" }
        problems << "the service is not Ready (latest revision did not start)" unless ready && ready["status"] == "True"
      end

      if expect["containers"]
        missing = expect["containers"] - by_name.keys
        problems << "missing container(s): #{missing.join(', ')} (deployed: #{by_name.keys.join(', ')})" if missing.any?
      end

      if expect["service_account"] && !spec["serviceAccountName"].to_s.start_with?(expect["service_account"])
        problems << "the service account is #{spec['serviceAccountName'].inspect}, expected one starting with #{expect['service_account']}"
      end

      (expect["secrets"] || {}).each do |container, names|
        env = by_name[container]
        next unless env # already reported as a missing container

        names.each do |name|
          var = env.find { |e| e["name"] == name }
          next if var && var.dig("valueFrom", "secretKeyRef")

          problems << "container '#{container}': #{name} is not mounted from Secret Manager"
        end
      end

      Array(expect["no_plain_env"]).each do |name|
        holders = by_name.select { |_c, env| env.any? { |e| e["name"] == name && e.key?("value") } }.keys
        problems << "#{name} is stored in plain text on container(s): #{holders.join(', ')}" if holders.any?
      end

      (expect["status_json"] || {}).each do |key, wanted|
        section = key.sub(/_tier\z/, "")
        actual = status.is_a?(Hash) ? status.dig(section, "tier") : nil
        next if actual.to_s == wanted.to_s

        problems << "/status.json says #{section} is #{actual.nil? ? 'unknown' : actual.to_s}, expected #{wanted}"
      end

      problems
    end

    def initialize(env: ENV, out: $stdout)
      @env = env
      @out = out
    end

    def mode
      value = @env["WORKSHOP_EVAL_LIVE"].to_s.strip.downcase
      %w[off strict].include?(value) ? value : "warn"
    end

    def run(spec)
      return Result.new(:skipped, [], "live checks are switched off (WORKSHOP_EVAL_LIVE=off)") if mode == "off"

      project = @env["GOOGLE_CLOUD_PROJECT"].to_s.strip
      return Result.new(:skipped, [], "GOOGLE_CLOUD_PROJECT is not set") if project.empty?

      service_name = spec["service"] || "blog"
      region = @env["GOOGLE_CLOUD_REGION"].to_s.strip
      region = "europe-west1" if region.empty?
      expect = spec["expect"] || {}

      @out.puts "     ⏳ calling gcloud to read Cloud Run service '#{service_name}' in #{region} (project #{project}, up to #{timeout}s)..."
      stdout, stderr, state = capture(["gcloud", "run", "services", "describe", service_name, "--region", region,
                                       "--project", project, "--format=json"])
      return finish(["gcloud #{state_message(state, stderr)}"]) unless state == :ok

      service = parse(stdout)
      return finish(["gcloud answered, but not with the JSON of a service"]) unless service.is_a?(Hash) && service["spec"]

      status = nil
      if expect["status_json"]
        url = service.dig("status", "url").to_s
        if url.empty?
          return finish(self.class.evaluate(service, nil, expect) + ["the service has no URL yet"])
        end

        @out.puts "     ⏳ fetching #{url}/status.json (up to #{timeout}s)..."
        body, _err, curl_state = capture(["curl", "-s", "-f", "--max-time", timeout.to_s, "#{url}/status.json"])
        status = curl_state == :ok ? parse(body) : nil
        unless status.is_a?(Hash)
          # Say that the page could not be read, instead of guessing what it would have said.
          without_status = expect.reject { |key, _| key == "status_json" }
          return finish(self.class.evaluate(service, nil, without_status) +
                        ["could not read #{url}/status.json (no answer, an error page, or not JSON); try again in a minute"])
        end
      end

      finish(self.class.evaluate(service, status, expect))
    end

    private

    def timeout
      value = @env["WORKSHOP_EVAL_LIVE_TIMEOUT"].to_i
      value.positive? ? value : DEFAULT_TIMEOUT
    end

    def finish(problems)
      return Result.new(:passed, [], nil) if problems.empty?

      Result.new(mode == "strict" ? :failed : :warning, problems, nil)
    end

    def parse(text)
      JSON.parse(text)
    rescue JSON::ParserError
      nil
    end

    def state_message(state, stderr)
      case state
      when :timeout then "did not answer within #{timeout}s"
      when :missing then "is not installed or not on PATH"
      else "could not read the service: #{stderr.to_s.lines.map(&:strip).reject(&:empty?).last || 'no error message'}"
      end
    end

    # Runs a command with stdin closed and gcloud prompts disabled; kills it after the timeout.
    # Returns [stdout, stderr, :ok | :error | :timeout | :missing].
    def capture(cmd)
      child_env = @env.to_h.merge("CLOUDSDK_CORE_DISABLE_PROMPTS" => "1")
      out_r, out_w = IO.pipe
      err_r, err_w = IO.pipe
      pid = Process.spawn(child_env, *cmd, in: File::NULL, out: out_w, err: err_w, unsetenv_others: true)
      out_w.close
      err_w.close
      readers = [Thread.new { out_r.read }, Thread.new { err_r.read }]
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      status = nil
      until status
        _pid, status = Process.wait2(pid, Process::WNOHANG)
        break if status

        if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
          Process.kill("KILL", pid)
          Process.wait(pid)
          return ["", "", :timeout]
        end
        sleep 0.05
      end
      [readers[0].value, readers[1].value, status.success? ? :ok : :error]
    rescue Errno::ENOENT
      ["", "", :missing]
    ensure
      [out_r, err_r, out_w, err_w].each { |io| io.close if io && !io.closed? }
    end
  end
end
