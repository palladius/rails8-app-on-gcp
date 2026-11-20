# frozen_string_literal: true

require "net/http"
require "json"

# Translates and summarizes English blog posts into natural spoken Italian
# scripts for PodcastifierJob before Google Cloud Text-to-Speech synthesis.
#
# Authenticates strictly via keyless Vertex AI Application Default Credentials
# (ADC) with zero static API keys (`docs/CONSTITUTION.md` §1 & §6) and falls
# back in < 5ms to a deterministic Italian summary when offline.
module PodcastTranslationService
  DEFAULT_MODEL    = "gemini-3.5-flash-lite"
  DEFAULT_LOCATION = "global"
  SCOPE            = "https://www.googleapis.com/auth/cloud-platform"
  OPEN_TIMEOUT     = 5
  READ_TIMEOUT     = 20
  MAX_SCRIPT_CHARS = 450

  VALID_SEGMENT    = /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/
  VALID_LOCATION   = /\A[a-z0-9][a-z0-9-]*\z/
  GENERIC_INTRO    = "Benvenuti al podcast del blog! Oggi vi presentiamo una nuova puntata dedicata a Rails 8 e Google Cloud."

  EPISODE_THEMES = [
    [
      /\b(local baseline|localhost|bin\/dev|local disk)\b/,
      "l'ambiente di sviluppo locale su Rails 8",
      "Vediamo come avviare l'applicazione in locale su disco e database temporanei prima di passare a Google Cloud."
    ],
    [
      /\b(ephemeral|single container|stateless)\b/,
      "il primo deploy effimero su Cloud Run",
      "Vediamo perché un container singolo senza persistenza gestita perde i dati al riavvio e come prepararci a Cloud Storage."
    ],
    [
      /\b(cloud sql|postgresql|postgres)\b/,
      "la persistenza dei dati con Google Cloud SQL",
      "Approfondiamo il collegamento sicuro a Cloud SQL PostgreSQL tramite Cloud SQL Auth Proxy con mTLS."
    ],
    [
      /\b(gcs|activestorage|cloud storage|bucket|blob|signed urls?)\b/,
      "l'archiviazione privata su Google Cloud Storage",
      "Esploriamo come proteggere file e immagini in un bucket privato con URL firmati tramite credenziali IAM."
    ],
    [
      /\b(cloud run|sidecar|multi-container|docker|compose|solid queue|worker|puma|serverless)\b/,
      "l'architettura su Cloud Run e i worker Solid Queue",
      "Analizziamo il coordinamento tra server web, sidecar e job asincroni Solid Queue in produzione."
    ],
    [
      /\b(iap|iam|oauth|security|secret|credentials|zero-trust)\b/,
      "la sicurezza e le identità gestite su Google Cloud",
      "Scopriamo le migliori pratiche zero-trust con Identity-Aware Proxy, IAM e Secret Manager."
    ],
    [
      /\b(gemini|vertex|imagen|nanobanana|podcast|tts|genai)\b/,
      "le pipeline generative con Vertex AI e Cloud TTS",
      "Vediamo come integrare modelli generativi tramite Application Default Credentials e sintesi vocale asincrona."
    ]
  ].freeze

  class Unavailable < StandardError; end

  module_function

  def project_id
    ENV["GOOGLE_CLOUD_PROJECT"].to_s.strip.presence
  end

  def current_location
    ENV["GOOGLE_CLOUD_LOCATION"].to_s.strip.downcase.presence || DEFAULT_LOCATION
  end

  def current_model
    ENV["PODCAST_TRANSLATION_MODEL"].to_s.strip.presence || DEFAULT_MODEL
  end

  # True when a Vertex AI call via Application Default Credentials could plausibly succeed.
  def available?
    project_id.present? && !credentials.nil?
  end

  # Always returns a spoken Italian script bounded for Cloud TTS (<= MAX_SCRIPT_CHARS).
  def translate_and_summarize(title:, body:)
    clean_title = sanitize_text(title)
    clean_body  = sanitize_text(body)
    return GENERIC_INTRO unless speakable_text?(clean_title) || speakable_text?(clean_body)

    if (project = project_id)
      translated = translate_via_vertex_ai(clean_title, clean_body, project: project)
      return translated if translated.present?
    else
      log_warn("PodcastTranslationService: GOOGLE_CLOUD_PROJECT is unset → using offline fallback")
    end

    fallback_script(clean_title, clean_body)
  end

  def prompt_for(title, body)
    build_prompt(sanitize_text(title), sanitize_text(body))
  end

  def build_prompt(clean_title, clean_body)
    safe_title = clean_title.to_s.tr("<>", " ").squish.truncate(200, separator: /\s/)
    safe_body  = clean_body.to_s.tr("<>", " ").squish.truncate(500, separator: /\s/)

    <<~PROMPT
      You are an engaging Italian podcast host for the "Rails 8 on Google Cloud" tech blog.
      Translate and summarize the article delimited below into natural spoken Italian.

      <article_title>#{safe_title}</article_title>
      <article_body>#{safe_body}</article_body>

      INSTRUCTIONS:
      1. Output ONLY 2-3 lively spoken Italian sentences as plain prose (under 400 characters).
      2. Begin with "Benvenuti al podcast del blog!".
      3. Translate technical concepts naturally into Italian.
      4. Do NOT include raw URLs, file paths, code snippets, markdown, asterisks, headers, quotes, bullet dashes, emojis, speaker labels, or bracketed tags.
    PROMPT
  end

  def endpoint_uri(project: project_id, location: current_location, model: current_model)
    proj = project.to_s.strip
    loc  = location.to_s.strip.downcase.presence || DEFAULT_LOCATION
    mod  = model.to_s.strip.presence || DEFAULT_MODEL

    raise ArgumentError, "Invalid Vertex AI project" unless proj.match?(VALID_SEGMENT)
    raise ArgumentError, "Invalid Vertex AI location" unless loc.match?(VALID_LOCATION)
    raise ArgumentError, "Invalid Vertex AI model" unless mod.match?(VALID_SEGMENT)

    host = case loc
           when "global" then "aiplatform.googleapis.com"
           when "us", "eu" then "aiplatform.#{loc}.rep.googleapis.com"
           else "#{loc}-aiplatform.googleapis.com"
           end

    URI::HTTPS.build(
      host: host,
      path: "/v1/projects/#{proj}/locations/#{loc}/publishers/google/models/#{mod}:generateContent"
    )
  end

  def request_body(prompt)
    {
      contents: [ { role: "user", parts: [ { text: prompt } ] } ],
      generationConfig: { maxOutputTokens: 1024, thinkingConfig: { thinkingLevel: "LOW" } }
    }
  end

  def translate_via_vertex_ai(clean_title, clean_body, project: project_id)
    loc = current_location
    mod = current_model
    uri = endpoint_uri(project: project, location: loc, model: mod)

    response = post_generate_content(uri, request_body(build_prompt(clean_title, clean_body)), access_token!)
    unless response.is_a?(Net::HTTPSuccess)
      log_warn("PodcastTranslationService: Vertex AI HTTP #{response.code} (#{mod} @ #{loc}): #{sanitize_log(response.body)} → using offline fallback")
      return nil
    end

    text = extract_text(response)
    if text.present?
      log_info("PodcastTranslationService: translated via Vertex AI (#{mod} @ #{loc})")
      return text
    end

    log_warn("PodcastTranslationService: Vertex AI returned empty or thought-only response (#{mod} @ #{loc}) → using offline fallback")
    nil
  rescue Unavailable, Timeout::Error, SocketError, IOError, SystemCallError,
         OpenSSL::SSL::SSLError, Net::ProtocolError, Net::HTTPBadResponse,
         Net::HTTPHeaderSyntaxError, Zlib::Error, JSON::JSONError, URI::Error, ArgumentError => e
    log_warn("PodcastTranslationService: #{e.class} (#{sanitize_log(e.message)}) → using offline fallback")
    nil
  end

  def extract_text(response)
    parsed = JSON.parse(response.body.to_s)
    return nil unless parsed.is_a?(Hash)

    candidates = parsed["candidates"]
    content = candidates.is_a?(Array) && candidates.first.is_a?(Hash) ? candidates.first["content"] : nil
    parts = content.is_a?(Hash) ? content["parts"] : nil
    return nil unless parts.is_a?(Array)

    raw_text = parts
      .filter_map { |part| part["text"] if part.is_a?(Hash) && part["text"].is_a?(String) && !part["thought"] }
      .join(" ")

    clean = clean_spoken_text(raw_text)
    return nil unless clean.match?(/[\p{L}\p{N}]/)

    bound_spoken_script(clean)
  end

  def credentials
    require "googleauth"
    Google::Auth.get_application_default([ SCOPE ])
  rescue LoadError, StandardError => e
    log_debug { "PodcastTranslationService: ADC unavailable (#{e.class}: #{sanitize_log(e.message)})" }
    nil
  end

  def access_token!
    creds = credentials or raise Unavailable, "no Application Default Credentials (run `gcloud auth application-default login`)"
    token = creds.fetch_access_token!
    resolved = (token.is_a?(Hash) && token["access_token"]).presence || creds.access_token
    raise Unavailable, "empty access token" if resolved.blank?

    resolved
  rescue Unavailable
    raise
  rescue StandardError => e
    raise Unavailable, "could not obtain an access token (#{e.class}: #{sanitize_log(e.message)})"
  end

  # Single network seam; unit tests stub this method (`docs/CONSTITUTION.md` §6).
  def post_generate_content(uri, body, token)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{token}"
    request["Content-Type"]  = "application/json"
    request.body = JSON.generate(body)

    Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
      http.request(request)
    end
  end

  # --- Deterministic Content-Aware Offline Fallback (< 5ms) ---

  def fallback_script(clean_title, clean_body)
    theme, closing = match_episode_theme(clean_title.downcase, clean_body.downcase)

    script =
      if theme
        "Benvenuti al podcast del blog! Nella puntata di oggi affrontiamo #{theme}. #{closing}"
      else
        safe_title = clean_spoken_title(clean_title)
        if safe_title.present?
          "Benvenuti al podcast del blog! Oggi vi presentiamo l'articolo #{safe_title}. #{closing}"
        else
          GENERIC_INTRO
        end
      end

    bound_spoken_script(script.squish)
  end

  def speakable_text?(text)
    text.to_s.gsub(/\[[^\]\n]+\]/, " ").match?(/[\p{L}\p{N}]/)
  end

  def match_episode_theme(title_lower, body_lower)
    [ title_lower, body_lower ].each do |text|
      EPISODE_THEMES.each do |pattern, theme, closing|
        return [ theme, closing ] if text.match?(pattern)
      end
    end

    [ nil, "Una nuova puntata dedicata allo sviluppo moderno con Rails 8 su Google Cloud." ]
  end

  def clean_spoken_title(title)
    cleaned = title.to_s
      .gsub(/\[[^\]\n]+\]/, " ")
      .gsub(/[^\p{L}\p{N}\s.,:?!'’\-]/, " ")
      .squish
      .gsub(/\s+([.,!?:])/, '\1')
      .sub(/\A[.,:?!\-\s]+/, "")
      .truncate(140, separator: /\s/, omission: "")
      .sub(/[.,:?!\-\s]+\z/, "")
    cleaned.match?(/[\p{L}\p{N}]/) ? cleaned : ""
  end

  def clean_spoken_text(raw_text)
    raw_text.to_s
      .gsub(/\[[^\]\n]+\]/, " ")
      .gsub(/(?:^|\n)\s*[-*]\s+/, " ")
      .gsub(/[*_`#"]/, "")
      .gsub(/[^\p{L}\p{N}\p{P}\s]/, " ")
      .squish
      .gsub(/\s+([.,!?;:])/, '\1')
  end

  def sanitize_text(text)
    safe = text.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    spaced = safe
      .gsub(/<(br|p|div|li|tr|td|th|h[1-6]|blockquote)\b/i, ' <\1')
      .gsub(/<(?:\/(?:p|div|li|tr|td|th|h[1-6]|blockquote)|br\s*\/?)>/i, '\& ')
    Loofah.fragment(spaced).scrub!(:prune).text(encode_special_chars: false).squish
  end

  def bound_spoken_script(text, max_len = MAX_SCRIPT_CHARS)
    normalized = text.to_s.squish
    return normalized if normalized.length <= max_len

    # Use offset max_len - 1 so lookahead (?=\s) distinguishes a decimal ("8.1") at max_len - 1 from a sentence end.
    sentence_end = normalized.rindex(/[.!?](?=\s)/, max_len - 1)
    return normalized[0..sentence_end] if sentence_end && sentence_end >= (max_len / 2)

    normalized.truncate(max_len, separator: /\s/)
  end

  def sanitize_log(text, max_len = 350)
    text.to_s
      .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      .gsub(/[[:cntrl:]]/, " ")
      .squish
      .truncate(max_len)
  end

  def log_info(msg)
    Rails.logger.info("🎙️ #{msg}") if Rails.logger
  end

  def log_warn(msg)
    Rails.logger.warn("🎙️ #{msg}") if Rails.logger
  end

  def log_debug(&block)
    Rails.logger.debug { "🎙️ #{block.call}" } if Rails.logger
  end
end
