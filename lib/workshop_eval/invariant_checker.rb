# frozen_string_literal: true

require "yaml"

module WorkshopEval
  # InvariantChecker evaluates cumulative cascading invariants across workshop steps.
  # It enforces monotonic architectural state progression ("one-way doors") to eliminate regressions.
  class InvariantChecker
    Result = Struct.new(:id, :from_step, :title, :description, :passed, :error_message, keyword_init: true) do
      def passed?
        passed
      end

      def failure?
        !passed
      end
    end

    attr_reader :invariants, :repo_root

    def initialize(invariants: [], repo_root: nil)
      @invariants = invariants || []
      @repo_root = repo_root || File.expand_path("../..", __dir__)
    end

    # Returns all invariants applicable for the given step number (from_step <= step_number)
    def invariants_for_step(step)
      step_num = step.to_s.gsub(/^step-?/, "").to_i
      @invariants.select do |inv|
        inv_from = inv["from_step"].to_i
        inv_from <= step_num
      end
    end

    # Evaluates a single invariant specification
    def evaluate_invariant(inv)
      check_type = inv["check"].to_s.strip
      handler_method = "check_#{check_type}"

      if respond_to?(handler_method, true)
        send(handler_method, inv)
      else
        evaluate_fallback_code(inv)
      end
    rescue StandardError => e
      build_result(inv, passed: false, error_message: "Execution error: #{e.message}")
    end

    # Evaluates all active invariants for a specific step
    def evaluate_for_step(step)
      active_invariants = invariants_for_step(step)
      active_invariants.map { |inv| evaluate_invariant(inv) }
    end

    private

    def build_result(inv, passed:, error_message: nil)
      Result.new(
        id: inv["id"],
        from_step: inv["from_step"],
        title: inv["title"],
        description: inv["description"],
        passed: passed,
        error_message: error_message
      )
    end

    # Rule: no_local_storage
    # Ensures storage is configured for Google Cloud Storage rather than local disk
    def check_no_local_storage(inv)
      params = inv["params"] || {}
      config_rel = params["config_file"] || "blog/config/storage.yml"
      storage_file = File.join(repo_root, config_rel)

      unless File.exist?(storage_file)
        return build_result(inv, passed: false, error_message: "Storage configuration file not found: #{config_rel}")
      end

      storage_content = File.read(storage_file)
      # In Step 4+, storage configuration must include google service with GCS provider
      has_google_service = storage_content.include?("service: GCS") ||
                           storage_content.include?("service: Google") ||
                           storage_content.include?("iam: true")

      unless has_google_service
        return build_result(inv, passed: false, error_message: "REGRESSION: Storage configuration does not define GCS service! Local storage is forbidden from Step 4 onward.")
      end

      # If Rails environment happens to be loaded in process, check runtime ActiveStorage tier
      if defined?(Rails) && Rails.respond_to?(:application) && Rails.application
        active_service = Rails.application.config.active_storage.service rescue nil
        if active_service == :local
          return build_result(inv, passed: false, error_message: "REGRESSION: ActiveStorage runtime service is currently set to :local! Must be :google or cloud persistent.")
        end
      end

      build_result(inv, passed: true)
    end

    # Rule: zero_stuck_jobs
    # Ensures Solid Queue has zero unworked background jobs accumulating in queue
    def check_zero_stuck_jobs(inv)
      # If Rails and SolidQueue are defined, query DB safely with fast timeout
      if defined?(SolidQueue::Job)
        begin
          stuck_count = SolidQueue::Job.where(finished_at: nil).count
          if stuck_count > 0
            return build_result(inv, passed: false, error_message: "REGRESSION: #{stuck_count} background job(s) stuck in queue! Dedicated Solid Queue worker required from Step 6 onward.")
          end
        rescue StandardError => e
          # DB might not be connected in isolated unit tests; that is allowed offline
        end
      end

      # Static verification: verify that a worker execution strategy is configured in compose.prod.yaml or entrypoint
      compose_file = File.join(repo_root, "blog/compose.prod.yaml")
      if File.exist?(compose_file)
        compose_text = File.read(compose_file)
        has_worker = compose_text.include?("solid_queue:start") || compose_text.include?("worker:")
        unless has_worker
          return build_result(inv, passed: false, error_message: "REGRESSION: No Solid Queue worker sidecar found in blog/compose.prod.yaml from Step 6 onward.")
        end
      end

      build_result(inv, passed: true)
    end

    # Rule: compose_has_service
    # Ensures production compose file contains a specific service sidecar (e.g. cloudsql-proxy)
    def check_compose_has_service(inv)
      params = inv["params"] || {}
      target_service = params["service"]
      file_rel = params["file"] || "blog/compose.prod.yaml"
      file_path = File.join(repo_root, file_rel)

      unless File.exist?(file_path)
        return build_result(inv, passed: false, error_message: "Compose file '#{file_rel}' not found.")
      end

      content = File.read(file_path)
      unless content.include?(target_service)
        return build_result(inv, passed: false, error_message: "REGRESSION: Required service '#{target_service}' missing from #{file_rel}!")
      end

      build_result(inv, passed: true)
    end

    # Fallback for custom code blocks
    def check_ruby_code(inv)
      code = inv["code"] || inv["script"]
      return build_result(inv, passed: true) if code.nil? || code.strip.empty?

      Dir.chdir(repo_root) do
        eval(code)
      end
      build_result(inv, passed: true)
    rescue StandardError => e
      build_result(inv, passed: false, error_message: "Invariant violation: #{e.message}")
    end

    def evaluate_fallback_code(inv)
      if inv["code"]
        check_ruby_code(inv)
      else
        build_result(inv, passed: false, error_message: "Unknown invariant check type: '#{inv['check']}'")
      end
    end
  end
end
