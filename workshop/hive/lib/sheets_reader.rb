# frozen_string_literal: true

require "json"
require "time"
require "uri"

module WorkshopHive
  class SheetsReader
    CACHE_TTL_SECONDS = 8
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

    def self.fetch_entries(sheet_id: ENV.fetch("HIVE_SPREADSHEET_ID", DEFAULT_SPREADSHEET_ID), credentials: nil, max_age: nil, deduplicate: true)
      raw_entries = get_raw_entries(sheet_id: sheet_id, credentials: credentials)
      filtered = filter_by_max_age(raw_entries, max_age)
      deduplicate ? deduplicate_by_url(filtered) : filtered
    end

    def self.get_raw_entries(sheet_id:, credentials:)
      now = Time.now.to_i
      if @cache && (now - @cache_timestamp < CACHE_TTL_SECONDS)
        return @cache
      end

      # Priority 1: If HIVE_SPREADSHEET_ID (or HIVE_SHEET_CSV_URL) is provided
      if sheet_id && !sheet_id.strip.empty?
        # If public sheet or explicit CSV URL, attempt direct HTTP CSV export
        entries = fetch_from_public_csv(sheet_id) || (credentials ? fetch_from_google_sheets(sheet_id, credentials) : nil)
        if entries && !entries.empty?
          @cache = entries
          @cache_timestamp = now
          return @cache
        end
      end

      # Priority 2: If local CSV data file exists (or ENV['HIVE_CSV_FILE']), use it!
      csv_file = ENV.fetch("HIVE_CSV_FILE", File.join(__dir__, "..", "data", "leaderboard.csv"))
      if File.exist?(csv_file)
        require "csv"
        rows = CSV.read(csv_file)
        entries = parse_rows(rows)
        @cache = entries
        @cache_timestamp = now
        return @cache
      end

      # Priority 3: Fallback mock entries for local development & tests
      @cache = MOCK_ENTRIES
      @cache_timestamp = now
      @cache
    rescue StandardError => e
      warn "[SheetsReader] Error fetching from Google Sheets/CSV: #{e.message}. Falling back to cached/mock data."
      @cache || MOCK_ENTRIES
    end

    # Parses duration strings like "24h", "2d", "1mo", "30m", "1w" into seconds
    def self.parse_duration(str)
      return nil if str.nil? || str.to_s.strip.empty?
      s = str.to_s.strip.downcase

      case s
      when /^(\d+)\s*h(?:ours?)?$/
        $1.to_i * 3600
      when /^(\d+)\s*d(?:ays?)?$/
        $1.to_i * 86400
      when /^(\d+)\s*w(?:eeks?)?$/
        $1.to_i * 7 * 86400
      when /^(\d+)\s*mo(?:nths?)?$/
        $1.to_i * 30 * 86400
      when /^(\d+)\s*m(?:in(?:utes?)?)?$/
        $1.to_i * 60
      when /^(\d+)\s*s(?:ec(?:onds?)?)?$/
        $1.to_i
      when /^(\d+)$/
        # Default unit is seconds if raw number, or treat <= 72 as hours
        val = $1.to_i
        val <= 72 ? val * 3600 : val
      else
        nil
      end
    end

    def self.parse_timestamp(ts_str)
      return nil if ts_str.nil? || ts_str.to_s.strip.empty?
      str = ts_str.to_s.strip
      # Try ISO8601 or standard formats first
      Time.parse(str)
    rescue ArgumentError
      # Handle DD/MM/YYYY HH:MM:SS or MM/DD/YYYY HH:MM:SS
      if str =~ %r{^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?}
        p1, p2, year = $1.to_i, $2.to_i, $3.to_i
        hour = $4 ? $4.to_i : 0
        min = $5 ? $5.to_i : 0
        sec = $6 ? $6.to_i : 0
        # In Google Sheets from Italian/European locale it is usually DD/MM/YYYY; fallback to MM/DD/YYYY if p1 > 12
        day, month = (p1 > 12) ? [p1, p2] : [p2, p1] # Default assume DD/MM/YYYY when p1 <= 31 and p2 <= 12
        # Note: if both <= 12, Google Forms in IT locale is DD/MM/YYYY
        if p1 <= 12 && p2 <= 12
          day, month = p1, p2
        end
        Time.new(year, month, day, hour, min, sec) rescue nil
      else
        nil
      end
    end

    def self.filter_by_max_age(entries, max_age_param)
      seconds = parse_duration(max_age_param)
      return entries unless seconds && seconds > 0

      cutoff = Time.now - seconds
      entries.select do |entry|
        t = parse_timestamp(entry[:timestamp])
        # If timestamp cannot be parsed, keep the entry so it is not unfairly dropped
        t.nil? || t >= cutoff
      end
    end


    def self.parse_rows(rows, deduplicate: false)
      return [] if rows.nil? || rows.size <= 1

      header = rows[0].map(&:to_s).map(&:downcase)
      ts_idx = header.index { |h| h.include?("time") } || 0
      nick_idx = header.index { |h| h.include?("nick") || h.include?("name") } || 1
      url_idx = header.index { |h| h.include?("url") || h.include?("run") || h.include?("deploy") } || 2
      step_idx = header.index { |h| h.include?("step") || h.include?("level") }

      parsed = rows[1..].map do |row|
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

      deduplicate ? deduplicate_by_url(parsed) : parsed
    end

    # Deduplicates entries by normalized Cloud Run URL.
    # When duplicate Cloud Run URLs exist, retains the LAST occurrence (the second / latest submission).
    def self.deduplicate_by_url(entries)
      return [] if entries.nil? || entries.empty?

      entries.reverse.uniq { |e| normalize_url(e[:url]) }.reverse
    end

    # Normalizes URLs for accurate deduplication comparison:
    # - trims whitespace
    # - normalizes default scheme to https
    # - downcases hostname and scheme
    # - normalizes http to https for .run.app domains
    # - strips trailing slashes
    def self.normalize_url(url_str)
      return "" if url_str.nil? || url_str.to_s.strip.empty?

      str = url_str.to_s.strip
      str = "https://#{str}" unless str.start_with?("http://", "https://")

      uri = URI.parse(str)
      scheme = uri.scheme&.downcase || "https"
      host = uri.host&.downcase || ""
      port = uri.port
      if host.end_with?(".run.app")
        scheme = "https"
        port = 443 if port == 80
      end

      port_part = if (scheme == "http" && port == 80) || (scheme == "https" && port == 443) || port.nil?
                    ""
                  else
                    ":#{port}"
                  end
      path = uri.path.to_s.sub(/\/+$/, "")
      "#{scheme}://#{host}#{port_part}#{path}"
    rescue StandardError
      url_str.to_s.strip.downcase.sub(/\/+$/, "")
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



    DEFAULT_SPREADSHEET_ID = "195OYMjc_ib2nysltnZE6cNmBw7xtXQ5WRC8igi7_AtM"
    DEFAULT_GID = "1095789823"

    def self.fetch_from_public_csv(sheet_id_or_url)
      require "net/http"
      require "uri"
      require "csv"

      urls = []
      if sheet_id_or_url.start_with?("http://") || sheet_id_or_url.start_with?("https://")
        urls << sheet_id_or_url
      else
        gid = ENV.fetch("HIVE_SHEET_GID", DEFAULT_GID)
        # Google Visualization API endpoint (ultra-reliable for public sheets)
        urls << "https://docs.google.com/spreadsheets/d/#{sheet_id_or_url}/gviz/tq?tqx=out:csv&gid=#{gid}"
        urls << "https://docs.google.com/spreadsheets/d/#{sheet_id_or_url}/export?format=csv&gid=#{gid}"
      end

      urls.each do |url_str|
        uri = URI.parse(url_str)
        res = Net::HTTP.get_response(uri)
        # Follow up to 3 redirects if any
        3.times do
          break unless res.is_a?(Net::HTTPRedirection) && res["location"]
          uri = URI.parse(res["location"])
          res = Net::HTTP.get_response(uri)
        end

        next unless res.is_a?(Net::HTTPSuccess)
        next if res.body.include?("<!DOCTYPE html>") # Login/auth page returned instead of CSV
        next if res.body.strip.empty?

        rows = CSV.parse(res.body)
        parsed = parse_rows(rows)
        return parsed if parsed && !parsed.empty?
      end

      nil
    rescue StandardError => e
      warn "[SheetsReader] Failed to fetch public CSV: #{e.message}"
      nil
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
