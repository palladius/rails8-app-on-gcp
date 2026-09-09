# frozen_string_literal: true

require "json"
require "base64"
require "stringio"

module WorkshopHive
  class ServiceAccountLoader
    SHEETS_READONLY_SCOPE = "https://www.googleapis.com/auth/spreadsheets.readonly"

    def self.load_credentials_hash
      if (b64 = ENV["HIVE_SERVICE_ACCOUNT_KEY_B64"]) && !b64.strip.empty?
        decoded = Base64.decode64(b64.strip)
        return JSON.parse(decoded)
      end

      if (raw_json = ENV["HIVE_SERVICE_ACCOUNT_JSON"]) && !raw_json.strip.empty?
        return JSON.parse(raw_json.strip)
      end

      if (filepath = ENV["GOOGLE_APPLICATION_CREDENTIALS"]) && File.exist?(filepath)
        return JSON.parse(File.read(filepath))
      end

      nil
    rescue JSON::ParserError => e
      warn "[ServiceAccountLoader] Failed to parse credentials JSON: #{e.message}"
      nil
    end

    def self.load_authorizer
      hash = load_credentials_hash
      return nil unless hash

      begin
        require "googleauth"
        io = StringIO.new(hash.to_json)
        Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: io,
          scope: SHEETS_READONLY_SCOPE
        )
      rescue LoadError, StandardError => e
        warn "[ServiceAccountLoader] Failed to build GoogleAuth credentials: #{e.message}"
        nil
      end
    end
  end
end
