# frozen_string_literal: true

require "net/http"
require "json"
require "base64"

class CloudTtsService
  SCOPE = "https://www.googleapis.com/auth/cloud-platform"
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 30

  class << self
    def synthesize(text:, language_code: "it-IT", voice: "it-IT-Wavenet-A")
      return dummy_mp3_io if text.blank?

      token = access_token
      project = ENV["GOOGLE_CLOUD_PROJECT"]

      if token.blank? || project.blank?
        Rails.logger.warn "🎧 CloudTtsService: No ADC or GOOGLE_CLOUD_PROJECT found. Using fallback audio."
        return dummy_mp3_io
      end

      uri = URI("https://texttospeech.googleapis.com/v1/text:synthesize")
      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{token}"
      req["X-Goog-User-Project"] = project
      req["Content-Type"] = "application/json"
      req.body = JSON.generate({
        input: { text: text.truncate(500) },
        voice: { languageCode: language_code, name: voice },
        audioConfig: { audioEncoding: "MP3" }
      })

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        http.request(req)
      end

      if res.is_a?(Net::HTTPSuccess)
        data = JSON.parse(res.body)
        if (content = data["audioContent"]).present?
          return StringIO.new(Base64.decode64(content))
        end
      end

      Rails.logger.warn "🎧 CloudTtsService: TTS call failed (#{res.code}): #{res.body.truncate(100)}. Using fallback audio."
      dummy_mp3_io
    rescue StandardError => e
      Rails.logger.error "🎧 CloudTtsService error: #{e.message}. Using fallback audio."
      dummy_mp3_io
    end

    private

    def access_token
      require "googleauth"
      creds = Google::Auth.get_application_default([SCOPE])
      token = creds.fetch_access_token!
      (token.is_a?(Hash) && token["access_token"]).presence || creds.access_token
    rescue StandardError => e
      Rails.logger.debug { "🎧 CloudTtsService: ADC unavailable (#{e.message})" }
      nil
    end

    def dummy_mp3_io
      dummy_bytes = [0xFF, 0xFB, 0x90, 0x64, 0x00, 0x00, 0x00, 0x00] * 32
      StringIO.new(dummy_bytes.pack("C*"))
    end
  end
end
