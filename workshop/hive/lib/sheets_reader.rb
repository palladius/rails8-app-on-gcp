# frozen_string_literal: true

require "json"
require "time"

module WorkshopHive
  class SheetsReader
    CACHE_TTL_SECONDS = 30
    @cache = nil
    @cache_timestamp = 0

    MOCK_ENTRIES = [
      {
        nickname: "AdaLovelace",
        url: "https://rails8-workshop-ada-dot-uc.a.run.app",
        step: "Step 7: Vertex AI Nano Banana",
        step_number: 7,
        timestamp: "2026-09-09T14:10:00Z"
      },
      {
        nickname: "AlanTuring",
        url: "https://rails8-workshop-alan-dot-uc.a.run.app",
        step: "Step 5: Cloud Run Deploy",
        step_number: 5,
        timestamp: "2026-09-09T14:15:00Z"
      },
      {
        nickname: "GraceHopper",
        url: "https://rails8-workshop-grace-dot-uc.a.run.app",
        step: "Step 3: Cloud SQL Proxy",
        step_number: 3,
        timestamp: "2026-09-09T14:22:00Z"
      },
      {
        nickname: "DennisRitchie",
        url: "https://rails8-workshop-dennis-dot-uc.a.run.app",
        step: "Step 1: Local Baseline",
        step_number: 1,
        timestamp: "2026-09-09T14:30:00Z"
      }
    ].freeze

    def self.fetch_entries(sheet_id: ENV["HIVE_SPREADSHEET_ID"], credentials: nil)
      now = Time.now.to_i
      if @cache && (now - @cache_timestamp < CACHE_TTL_SECONDS)
        return @cache
      end

      # If local CSV data file exists (or ENV['HIVE_CSV_FILE']), use it!
      csv_file = ENV.fetch("HIVE_CSV_FILE", File.join(__dir__, "..", "data", "leaderboard.csv"))
      if File.exist?(csv_file)
        require "csv"
        rows = CSV.read(csv_file)
        entries = parse_rows(rows)
        @cache = entries
        @cache_timestamp = now
        return @cache
      end

      # If sheet_id is not set, use the mock entries for local development & tests
      if sheet_id.nil? || sheet_id.strip.empty?
        @cache = MOCK_ENTRIES
        @cache_timestamp = now
        return @cache
      end

      # Live Google Sheets API integration
      entries = fetch_from_google_sheets(sheet_id, credentials)
      @cache = entries
      @cache_timestamp = now
      @cache
    rescue StandardError => e
      warn "[SheetsReader] Error fetching from Google Sheets/CSV: #{e.message}. Falling back to cached/mock data."
      @cache || MOCK_ENTRIES
    end


    def self.parse_rows(rows)
      return [] if rows.nil? || rows.size <= 1

      header = rows[0].map(&:to_s).map(&:downcase)
      ts_idx = header.index { |h| h.include?("time") } || 0
      nick_idx = header.index { |h| h.include?("nick") || h.include?("name") } || 1
      url_idx = header.index { |h| h.include?("url") || h.include?("run") || h.include?("deploy") } || 2
      step_idx = header.index { |h| h.include?("step") || h.include?("level") }

      rows[1..].map do |row|
        url_str = row[url_idx].to_s.strip
        step_str = step_idx ? row[step_idx].to_s.strip : ""
        step_num = extract_step_number(step_str, url_str)

        {
          nickname: row[nick_idx].to_s.strip,
          url: url_str,
          step: step_str.empty? ? "Step #{step_num}" : step_str,
          step_number: step_num,
          timestamp: row[ts_idx].to_s.strip
        }
      end.reject { |e| e[:url].empty? }
    end

    def self.extract_step_number(step_str, url_str = "")
      if step_str =~ /step[- ]?(\d+)/i
        $1.to_i
      elsif step_str =~ /(\d+)/
        $1.to_i
      elsif url_str.include?(".run.app")
        5 # Deployed on Cloud Run = Step 5 (or higher)
      elsif url_str.include?("localhost")
        1 # Running locally = Step 1
      else
        0
      end
    end



    def self.fetch_from_google_sheets(sheet_id, credentials)
      require "google/apis/sheets_v4"
      service = Google::Apis::SheetsV4::SheetsService.new
      service.authorization = credentials if credentials

      range = ENV.fetch("HIVE_SHEET_RANGE", "A1:Z100")
      response = service.get_spreadsheet_values(sheet_id, range)
      parse_rows(response.values)
    end
  end
end
