# frozen_string_literal: true

class StatusesController < ApplicationController
  allow_unauthenticated_access only: [:show]

  def show
    # Run environment detection (0 ms)
    @run_env = detect_run_env

    # Database detection (0 ms)
    @db_status = detect_db_status

    # Storage detection (0 ms)
    @storage_status = detect_storage_status

    # AI detection (0 ms, purely in-memory / env inspection)
    @ai_status = detect_ai_status

    # Solid Queue / Background Jobs (0 ms)
    @jobs_status = detect_jobs_status

    # Workshop Step Auto-Inference (0 ms)
    @workshop_step = infer_workshop_step

    # Safe Non-Secret Environment Variables Inspection
    @env_inspection = safe_env_inspection

    # Overall system health
    @system_info = {
      app_version: ENV.fetch("APP_VERSION") { (File.read(Rails.root.join("VERSION")).strip rescue nil) || (File.read(Rails.root.join("../VERSION")).strip rescue nil) || "0.2.2" },
      ruby_version: RUBY_VERSION,
      rails_version: Rails.version,
      rails_env: Rails.env,
      admin_users_count: (User.count rescue 0),
      posts_count: (Post.count rescue 0),
      blobs_count: (ActiveStorage::Blob.count rescue 0),
      attachments_count: (ActiveStorage::Attachment.count rescue 0)
    }

    respond_to do |format|
      format.html
      format.json do
        render json: {
          system: @system_info,
          workshop_step: @workshop_step,
          run_env: @run_env,
          database: @db_status,
          storage: @storage_status,
          ai: @ai_status,
          jobs: @jobs_status,
          safe_environment: @env_inspection
        }
      end
    end
  end

  private

  def detect_run_env
    if ENV["K_SERVICE"].present? || ENV["RAILS8_ENV_LAUNCH_MODE"].to_s.downcase.include?("cloud run")
      {
        tier: :cloud_run,
        badge: "☁️ Google Cloud Run",
        color: "#059669",
        is_cloud: true,
        service_name: ENV["K_SERVICE"],
        revision_name: ENV["K_REVISION"],
        details: "Serverless container running on Cloud Run (Service: #{ENV['K_SERVICE'] || 'custom'})"
      }
    elsif File.exist?("/.dockerenv") || ENV["DOCKER_CONTAINER"].present? || ENV["RAILS8_ENV_LAUNCH_MODE"].to_s.downcase.include?("docker")
      {
        tier: :docker,
        badge: "🐳 Docker Compose",
        color: "#0284c7",
        is_cloud: false,
        details: "Containerized application running via Docker Compose (PostgreSQL)"
      }
    else
      {
        tier: :local_rails,
        badge: "💻 Local Rails (Host)",
        color: "#6366f1",
        is_cloud: false,
        details: "Running natively on host developer machine (#{`hostname`.strip rescue 'localhost'})"
      }
    end
  end

  def detect_db_status
    cfg = ActiveRecord::Base.connection_db_config
    adapter = cfg.adapter.to_s
    host = cfg.configuration_hash[:host].to_s
    is_cloudsql = ENV["CLOUDSQL_INSTANCE"].present? || host.include?("cloudsql") || ENV["DATABASE_URL"].to_s.include?("cloudsql")

    if is_cloudsql
      {
        tier: :cloud_sql,
        badge: "🟢 Google Cloud SQL",
        color: "#059669",
        persistent: true,
        adapter: adapter,
        details: "Managed Cloud SQL via Auth Proxy mTLS (Instance: #{ENV['CLOUDSQL_INSTANCE'] || 'Configured'})"
      }
    elsif adapter == "postgresql"
      {
        tier: :local_postgres,
        badge: "🟡 Local PostgreSQL",
        color: "#eab308",
        persistent: false,
        adapter: adapter,
        details: "PostgreSQL running locally or in Docker container (#{host.presence || 'localhost'})"
      }
    else
      {
        tier: :local_sqlite,
        badge: "🟡 Ephemeral SQLite",
        color: "#eab308",
        persistent: false,
        adapter: adapter,
        details: "Local SQLite file database (#{cfg.configuration_hash[:database]})"
      }
    end
  end

  def detect_storage_status
    service_name = Rails.configuration.active_storage.service.to_s
    tier = Nanobanana.storage_tier
    blobs_count = (ActiveStorage::Blob.count rescue 0)

    if tier == :gcs
      {
        tier: :gcs,
        badge: "☁️ Google Cloud Storage",
        color: "#0d9488",
        service: service_name,
        persistent: true,
        blobs_count: blobs_count,
        details: "Private GCS bucket with IAM Credentials blob signing (`iam: true`)"
      }
    else
      {
        tier: :local,
        badge: "💾 Ephemeral Local Disk",
        color: "#64748b",
        service: service_name,
        persistent: false,
        blobs_count: blobs_count,
        details: "Local filesystem storage (covers rendered in sad grayscale mode)"
      }
    end
  end

  def detect_ai_status
    has_api_key = Nanobanana.gemini_api_key.present?
    project_id = Nanobanana.project_id
    has_adc = !Nanobanana.credentials.nil?

    if has_api_key
      {
        mode: :gemini_api_key,
        badge: "🍌 Google AI Studio (API Key)",
        color: "#10b981",
        active: true,
        details: "Direct AI Studio API key configured (#{Nanobanana::MODEL})"
      }
    elsif project_id.present? && has_adc
      {
        mode: :vertex_ai,
        badge: "🍌 Vertex AI (Enterprise ADC)",
        color: "#059669",
        active: true,
        details: "Vertex AI via Application Default Credentials (Project: #{project_id}, Model: #{Nanobanana::MODEL})"
      }
    else
      {
        mode: :fake_fallback,
        badge: "🎭 Fake Cover Fallback",
        color: "#ef4444",
        active: false,
        details: "Neither GEMINI_API_KEY nor Vertex AI ADC available. Using bundled 1960s mock poster."
      }
    end
  end

  def detect_jobs_status
    pending = SolidQueue::Job.where(finished_at: nil).count rescue 0
    failed = SolidQueue::FailedExecution.count rescue 0

    {
      pending_count: pending,
      failed_count: failed,
      badge: pending > 0 ? "⚠️ #{pending} Pending Jobs" : "✅ Queue Drained",
      color: pending > 0 ? "#f59e0b" : "#10b981"
    }
  end

  # Auto-infers the current step based on active infrastructure & configurations
  def infer_workshop_step
    # Explicit override if student/teacher set WORKSHOP_STEP=N
    if ENV["WORKSHOP_STEP"].present?
      num = ENV["WORKSHOP_STEP"].to_i
      return { number: num, source: "Explicit (ENV['WORKSHOP_STEP'])", description: step_title_for(num) }
    end

    is_cloud_run = ENV["K_SERVICE"].present? || ENV["RAILS8_ENV_LAUNCH_MODE"].to_s.downcase.include?("cloud run")
    is_docker = File.exist?("/.dockerenv") || ENV["DOCKER_CONTAINER"].present? || ENV["RAILS8_ENV_LAUNCH_MODE"].to_s.downcase.include?("docker")
    is_cloud_sql = @db_status[:tier] == :cloud_sql
    is_gcs = @storage_status[:tier] == :gcs
    is_ai_live = @ai_status[:active]

    step_num =
      if is_cloud_run && is_cloud_sql && is_gcs && is_ai_live
        7 # Step 7: GenAI Pipelines & Gold Cloud
      elsif is_cloud_run && is_cloud_sql && is_gcs
        6 # Step 6: Deploy 3 - Enterprise Multi-Container Sidecars
      elsif is_cloud_sql
        5 # Step 5: Cloud SQL Ready & Secret Manager
      elsif is_gcs
        4 # Step 4: Private Cloud Storage
      elsif is_docker
        2 # Step 2: Docker Compose & Local Postgres
      elsif is_cloud_run
        3 # Step 3: Deploy 1 / 2 Standalone Cloud Run
      else
        1 # Step 1: Local Baseline (SQLite)
      end

    {
      number: step_num,
      source: "Auto-inferred from active architecture telemetry",
      description: step_title_for(step_num)
    }
  end

  def step_title_for(num)
    titles = {
      0 => "Step 0: Prerequisites & Toolchain Setup",
      1 => "Step 1: Local Rails 8 Baseline (SQLite)",
      2 => "Step 2: Containerized Local Dev (Docker Compose & Postgres)",
      3 => "Step 3: First Cloud Run Standalone Deployment",
      4 => "Step 4: Durable Storage with Google Cloud Storage (iam: true)",
      5 => "Step 5: Cloud SQL Ready & Secret Manager CLI Injection",
      6 => "Step 6: Deploy 3 — Enterprise Multi-Container Sidecars",
      7 => "Step 7: Generative AI Pipelines & Nano Banana",
      8 => "Step 8: Choose Your Own Adventure / Quests"
    }
    titles[num] || "Step #{num}: Active Milestone"
  end

  def safe_env_inspection
    # Known sensitive keys to strictly mask with asterisks
    secret_patterns = [/pass/i, /key/i, /secret/i, /token/i, /credential/i, /auth/i]

    # Inspection targets
    vars_of_interest = %w[
      GOOGLE_CLOUD_PROJECT
      GOOGLE_CLOUD_REGION
      GOOGLE_CLOUD_LOCATION
      GOOGLE_CLOUD_ACCOUNT
      NANOBANANA_MODEL
      ACTIVE_STORAGE_SERVICE
      CLOUDSQL_INSTANCE
      RAILS8_ENV_LAUNCH_MODE
      K_SERVICE
      K_REVISION
      K_CONFIGURATION
      PORT
      ADMIN_EMAIL
      ADMIN_PASSWORD
      GEMINI_API_KEY
      DATABASE_URL
    ]

    vars_of_interest.map do |var_name|
      val = ENV[var_name]
      is_secret = secret_patterns.any? { |pat| var_name.match?(pat) }
      display_value =
        if val.nil?
          "nil"
        elsif is_secret
          # Length-preserving asterisk masking
          "*" * [val.length, 4].max
        else
          val
        end

      {
        key: var_name,
        value: display_value,
        is_set: val.present?,
        is_secret: is_secret
      }
    end
  end
end
