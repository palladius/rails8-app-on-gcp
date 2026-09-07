module ApplicationHelper
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
