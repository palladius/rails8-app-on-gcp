# frozen_string_literal: true

require "json"
require "base64"

module WorkshopHive
  class ServiceAccountLoader
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
  end
end
