module ApplicationHelper
  # :local (ephemeral disk) or :gcs (private bucket). See Nanobanana.storage_tier.
  def storage_tier
    Nanobanana.storage_tier
  end

  # Cover images on local disk are shown in "sad" grayscale (issue #18): the
  # original bytes stay untouched, so the same image turns colorful again once
  # ActiveStorage moves to GCS. Generated covers are also grayscale server-side.
  def cover_image_classes(*extra)
    class_names(*extra, "cover-image--local" => storage_tier == :local)
  end

  def cover_image_title
    if storage_tier == :local
      "Stored on ephemeral local disk: sad grayscale mode 💾 (ask AI why!)"
    else
      "Stored as a private blob on Google Cloud Storage ☁️"
    end
  end

  def launch_mode_info
    raw = ENV["RAILS8_ENV_LAUNCH_MODE"].to_s.strip

    if raw.downcase.include?("docker")
      {
        badge: "🐳 Docker Compose · Postgres",
        tooltip: raw.presence || "Hello! I am the containerized app running on PostgreSQL via Docker Compose.",
        color: "#0284c7" # Docker blue
      }
    elsif raw.downcase.include?("cloud run") || raw.downcase.include?("serverless") || ENV["K_SERVICE"].present?
      {
        badge: "☁️ Google Cloud Run",
        tooltip: raw.presence || "Hello! I am running serverless on Google Cloud Run.",
        color: "#059669" # Cloud green
      }
    elsif raw.present?
      {
        badge: "💻 Local Rails · SQLite",
        tooltip: raw,
        color: "#6366f1" # Indigo/purple
      }
    else
      # Auto-detection fallback if ENV is not set
      if File.exist?("/.dockerenv") || ENV["DOCKER_CONTAINER"].present?
        {
          badge: "🐳 Docker Compose · Postgres",
          tooltip: "Hello! I am the containerized app running on PostgreSQL via Docker Compose.",
          color: "#0284c7"
        }
      else
        {
          badge: "💻 Local Rails · SQLite",
          tooltip: "Hello! I am the native app launched with bin/dev on local SQLite.",
          color: "#6366f1"
        }
      end
    end
  end
end
