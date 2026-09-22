# frozen_string_literal: true

require "time"
require "yaml"

class FrictionLog
  REQUIRED_FIELDS = %w[
    id title runner account gcp_project_id ghi_url pr_urls
    started_at ended_at pauses active_duration_seconds
    wall_clock_duration_seconds code_commit workshop_commit
    eval_score bugs_found_count status steps
  ].freeze

  VALID_STATUSES = %w[success blocked abandoned partial].freeze
  VALID_STEP_STATUSES = %w[completed skipped failed partial].freeze

  attr_reader :raw_data, :errors

  def initialize(data)
    @raw_data = data.is_a?(Hash) ? data : {}
    @errors = []
  end

  def id
    @raw_data["id"].to_s
  end

  def title
    @raw_data["title"].to_s
  end

  def runner
    @raw_data["runner"].to_s
  end

  def account
    @raw_data["account"].to_s
  end

  def gcp_project_id
    @raw_data["gcp_project_id"].to_s
  end

  def ghi_url
    @raw_data["ghi_url"].to_s
  end

  def pr_urls
    Array(@raw_data["pr_urls"])
  end

  def started_at
    @raw_data["started_at"].to_s
  end

  def ended_at
    @raw_data["ended_at"].to_s
  end

  def started_time
    Time.iso8601(started_at) rescue nil
  end

  def ended_time
    Time.iso8601(ended_at) rescue nil
  end

  def pauses
    Array(@raw_data["pauses"])
  end

  def paused?
    !pauses.empty?
  end

  def pause_duration_seconds
    pauses.sum do |p|
      s = Time.iso8601(p["started_at"].to_s) rescue nil
      r = Time.iso8601(p["resumed_at"].to_s) rescue nil
      (s && r) ? (r - s).to_i : 0
    end
  end

  def active_duration_seconds
    @raw_data["active_duration_seconds"].to_i
  end

  def wall_clock_duration_seconds
    @raw_data["wall_clock_duration_seconds"].to_i
  end

  def calculated_active_duration_seconds
    wall_clock_duration_seconds - pause_duration_seconds
  end

  def code_commit
    @raw_data["code_commit"] || {}
  end

  def code_commit_sha
    code_commit["sha"].to_s
  end

  def code_commit_pushed_at
    code_commit["pushed_at"].to_s
  end

  def workshop_commit
    @raw_data["workshop_commit"] || {}
  end

  def workshop_commit_sha
    workshop_commit["sha"].to_s
  end

  def workshop_commit_pushed_at
    workshop_commit["pushed_at"].to_s
  end

  def eval_score
    @raw_data["eval_score"].to_s
  end

  def bugs_found_count
    @raw_data["bugs_found_count"].to_i
  end

  def status
    @raw_data["status"].to_s
  end

  def steps
    raw_steps = @raw_data["steps"] || {}
    # ensure keys are integers
    raw_steps.transform_keys { |k| k.to_i rescue k }
  end

  def step(index)
    steps[index.to_i] || {}
  end

  def total_step_errors
    steps.values.sum { |s| s["errors_count"].to_i }
  end

  def total_step_warnings
    steps.values.sum { |s| s["warnings_count"].to_i }
  end

  def total_step_duration_seconds
    steps.values.sum { |s| s["duration_seconds"].to_i }
  end

  def valid?
    @errors = []

    validate_required_fields
    validate_timestamps
    validate_durations
    validate_steps
    validate_status

    @errors.empty?
  end

  def to_h
    @raw_data
  end

  def self.load_all(yaml_file_path)
    raise Errno::ENOENT, "File not found: #{yaml_file_path}" unless File.exist?(yaml_file_path)

    data = YAML.safe_load_file(yaml_file_path, permitted_classes: [Date, Time])
    logs_data = data.is_a?(Hash) && data["friction_logs"] ? data["friction_logs"] : data
    Array(logs_data).map { |d| new(d) }
  end

  private

  def validate_required_fields
    REQUIRED_FIELDS.each do |field|
      if @raw_data[field].nil?
        @errors << "missing required field: #{field}"
      end
    end
  end

  def validate_timestamps
    s = started_time
    e = ended_time

    @errors << "started_at must be valid ISO8601" unless s
    @errors << "ended_at must be valid ISO8601" unless e

    if s && e && e < s
      @errors << "ended_at cannot be earlier than started_at"
    end

    pauses.each_with_index do |p, idx|
      ps = Time.iso8601(p["started_at"].to_s) rescue nil
      pr = Time.iso8601(p["resumed_at"].to_s) rescue nil
      @errors << "pause #{idx} started_at must be valid ISO8601" unless ps
      @errors << "pause #{idx} resumed_at must be valid ISO8601" unless pr
      if ps && pr && pr < ps
        @errors << "pause #{idx} resumed_at cannot be earlier than started_at"
      end
    end
  end

  def validate_durations
    if wall_clock_duration_seconds < active_duration_seconds
      @errors << "wall_clock_duration cannot be less than active_duration"
    end

    if active_duration_seconds < 0
      @errors << "active_duration cannot be negative"
    end
  end

  def validate_steps
    (0..8).each do |i|
      st = step(i)
      if st.empty?
        @errors << "missing step #{i}"
      else
        step_status = st["status"].to_s
        unless VALID_STEP_STATUSES.include?(step_status)
          @errors << "invalid status '#{step_status}' for step #{i}"
        end
      end
    end
  end

  def validate_status
    unless VALID_STATUSES.include?(status)
      @errors << "invalid overall status '#{status}'"
    end
  end
end
