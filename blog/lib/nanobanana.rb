# frozen_string_literal: true

require "net/http"
require "json"
require "base64"

# Nano Banana cover-image generator (GitHub issue #18).
#
# When a Post is saved without a cover image, GenerateCoverImageJob asks
# Google's "Nano Banana" model (gemini-2.5-flash-image) on Vertex AI for a
# vintage 1960s Italian movie poster inspired by the article. Authentication is
# Application Default Credentials only (issue #14): the attached service account
# on Cloud Run, `gcloud auth application-default login` on a laptop. No API keys.
#
# Two constitutional rules shape this module (docs/CONSTITUTION.md):
# * §6 Localhost invariant — it must never crash without cloud credentials.
#   Anything that goes wrong falls back to a bundled, honest "fake" cover.
# * §5 Asset provenance — the image must show WHERE it lives: grayscale plus a
#   house/127.0.0.1 stamp on local disk, a colorful cloud stamp on GCS.
module Nanobanana
  MODEL    = ENV.fetch("NANOBANANA_MODEL", "gemini-2.5-flash-image")
  LOCATION = ENV.fetch("GOOGLE_CLOUD_LOCATION", "global")
  SCOPE    = "https://www.googleapis.com/auth/cloud-platform"

  MIN_INTELLIGIBLE_BYTES = 30
  OPEN_TIMEOUT = 5   # seconds
  READ_TIMEOUT = 90  # seconds — image generation is slow

  IMAGES_DIR = Rails.root.join("app/assets/images")
  FAKE_COVER = IMAGES_DIR.join("nanobanana_fake_cover.png")
  STAMPS     = {
    local: IMAGES_DIR.join("nanobanana_stamp_local.png"),
    gcs:   IMAGES_DIR.join("nanobanana_stamp_cloud.png")
  }.freeze

  # "qwerty"-style keyboard mash, a key held down, or vowel-less gibberish.
  KEYBOARD_MASH = [ /qwert/i, /asdf/i, /zxcv/i, /hjkl/i, /(.)\1{4,}/, /\b[b-df-hj-np-tv-z]{7,}\b/i ].freeze

  Result = Data.define(:data, :content_type, :source) # source: :vertex | :fake

  class Unavailable < StandardError; end

  module_function

  # Riccardo's rule: below 30 bytes, or random keyboard noise, is not worth
  # illustrating — we celebrate Prog Metal in Modena instead.
  def unintelligible_or_too_short?(title, body)
    text = "#{title} #{body}".strip
    return true if text.bytesize < MIN_INTELLIGIBLE_BYTES

    KEYBOARD_MASH.any? { |pattern| text.match?(pattern) }
  end

  def prompt_for(title, body)
    subject =
      if unintelligible_or_too_short?(title, body)
        <<~SUBJECT
          The poster advertises an epic progressive metal concert in Modena, Italy:
          the Ghirlandina tower and Piazza Grande in the background, a wall of
          amplifiers, dramatic stage lights, casks of balsamic vinegar, and a
          virtuoso band caught mid-solo.
        SUBJECT
      else
        <<~SUBJECT
          The poster is the cover image for a blog post titled "#{title}".
          The article contains the following text: "#{body.to_s.squish.truncate(500)}".
        SUBJECT
      end

    <<~PROMPT
      #{subject.strip}

      CRITICAL STYLE INSTRUCTION: The image MUST be rendered in the style of a
      "Locandina di un film 1960" (a vintage 1960s Italian movie poster).
      Maintain a beautiful, cohesive vintage Italian cinematic aesthetic.
      You MUST feature a banana somewhere in the scene.
      You MUST place a shiny red ruby gem shaped like the digit "8" in the
      top-right corner of the image.
    PROMPT
  end

  def gemini_api_key
    ENV["GEMINI_API_KEY"].presence
  end

  def project_id
    ENV["GOOGLE_CLOUD_PROJECT"].presence || ENV["GCP_PROJECT_ID"].presence
  end

  # True when a Vertex AI call or Gemini API key call could plausibly succeed.
  def available?
    gemini_api_key.present? || (project_id.present? && !credentials.nil?)
  end

  # Always returns a Result. Gemini API Key or Vertex AI when possible, fake cover otherwise.
  def generate_image(prompt)
    if gemini_api_key.present?
      generate_via_gemini_api(prompt)
    elsif project_id.present?
      generate_via_vertex_ai(prompt)
    else
      fake_cover("Neither GEMINI_API_KEY nor GOOGLE_CLOUD_PROJECT is set")
    end
  end

  # :gcs when ActiveStorage points at a Google Cloud Storage service, :local
  # otherwise. Same rule as the footer badge in layouts/application.html.erb.
  def storage_tier
    Rails.configuration.active_storage.service.to_s.start_with?("google") ? :gcs : :local
  end

  # Returns PNG bytes. Local disk is ephemeral and sad, hence grayscale plus a
  # little house; GCS is persistent and happy, hence a colorful cloud.
  # Cosmetic step: on any failure the original bytes are returned untouched.
  def stamp_provenance(data, tier: storage_tier)
    require "vips"

    image = Vips::Image.new_from_buffer(data, "")
    image = image.colourspace(:b_w).colourspace(:srgb) if tier == :local

    stamp  = Vips::Image.new_from_file(STAMPS.fetch(tier).to_s).colourspace(:srgb)
    stamp  = stamp.bandjoin(255) unless stamp.has_alpha?
    width  = [ (image.width * 0.14).round, 48 ].max
    stamp  = stamp.resize(width.to_f / stamp.width)
    margin = (image.width * 0.03).round

    image
      .composite2(stamp, :over, x: image.width - stamp.width - margin, y: image.height - stamp.height - margin)
      .write_to_buffer(".png")
  rescue LoadError, StandardError => e
    Rails.logger.warn "🍌 Nano Banana: provenance stamping skipped (#{e.class}: #{e.message})"
    data
  end

  # --- internals (still callable, module_function makes them stubbable in tests)

  def generate_via_gemini_api(prompt)
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{MODEL}:generateContent?key=#{gemini_api_key}")
    response = post_generate_content(uri, request_body(prompt), nil)
    unless response.is_a?(Net::HTTPSuccess)
      return fake_cover("Gemini API answered HTTP #{response.code}: #{response.body.to_s.squish.truncate(200)}")
    end

    part = JSON.parse(response.body).dig("candidates", 0, "content", "parts")&.find { |p| p["inlineData"] }
    return fake_cover("Gemini API returned no image part") unless part

    Rails.logger.info "🍌 Nano Banana: cover generated via Google AI Studio (#{MODEL})"
    Result.new(
      data: Base64.decode64(part["inlineData"]["data"]),
      content_type: part["inlineData"]["mimeType"].presence || "image/png",
      source: :vertex
    )
  rescue Unavailable, Timeout::Error, SocketError, IOError, SystemCallError,
         OpenSSL::SSL::SSLError, Net::ProtocolError, JSON::ParserError => e
    fake_cover("#{e.class}: #{e.message.to_s.squish.truncate(200)}")
  end

  def generate_via_vertex_ai(prompt)
    response = post_generate_content(endpoint_uri, request_body(prompt), access_token!)
    unless response.is_a?(Net::HTTPSuccess)
      return fake_cover("Vertex AI answered HTTP #{response.code}: #{response.body.to_s.squish.truncate(200)}")
    end

    part = JSON.parse(response.body).dig("candidates", 0, "content", "parts")&.find { |p| p["inlineData"] }
    return fake_cover("Vertex AI returned no image part") unless part

    Rails.logger.info "🍌 Nano Banana: cover generated via Vertex AI (#{MODEL} @ #{LOCATION})"
    Result.new(
      data: Base64.decode64(part["inlineData"]["data"]),
      content_type: part["inlineData"]["mimeType"].presence || "image/png",
      source: :vertex
    )
  rescue Unavailable, Timeout::Error, SocketError, IOError, SystemCallError,
         OpenSSL::SSL::SSLError, Net::ProtocolError, JSON::ParserError => e
    fake_cover("#{e.class}: #{e.message.to_s.squish.truncate(200)}")
  end

  def endpoint_uri
    host = LOCATION == "global" ? "aiplatform.googleapis.com" : "#{LOCATION}-aiplatform.googleapis.com"
    URI("https://#{host}/v1/projects/#{project_id}/locations/#{LOCATION}/publishers/google/models/#{MODEL}:generateContent")
  end

  def request_body(prompt)
    {
      contents: [ { role: "user", parts: [ { text: prompt } ] } ],
      generationConfig: { responseModalities: %w[IMAGE TEXT] }
    }
  end

  def credentials
    require "googleauth"
    Google::Auth.get_application_default([ SCOPE ])
  rescue LoadError, StandardError => e
    Rails.logger.debug { "🍌 Nano Banana: no Application Default Credentials (#{e.class}: #{e.message})" }
    nil
  end

  def access_token!
    creds = credentials or raise Unavailable, "no Application Default Credentials (run `gcloud auth application-default login`)"
    token = creds.fetch_access_token!
    (token.is_a?(Hash) && token["access_token"]).presence || creds.access_token
  rescue Unavailable
    raise
  rescue StandardError => e
    raise Unavailable, "could not obtain an access token (#{e.class}: #{e.message})"
  end

  # The only method that touches the network; tests stub it.
  def post_generate_content(uri, body, token)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{token}" if token
    request["Content-Type"]  = "application/json"
    request.body = JSON.generate(body)

    Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
      http.request(request)
    end
  end

  def fake_cover(reason)
    Rails.logger.warn "🍌 Nano Banana: #{reason} → using the bundled fake cover image"
    Result.new(data: File.binread(FAKE_COVER), content_type: "image/png", source: :fake)
  end
end
