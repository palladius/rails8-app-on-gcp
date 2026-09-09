# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# --- Admin User Bootstrapping & Guard Gate (Issue #21 & #29) ---
# Primary Google Cloud identity for IAM, billing, ADC, IAP, and blog administrator.
admin_email = (ENV["GOOGLE_CLOUD_ACCOUNT"] || ENV["GOOGLE_CLOUD_EMAIL"] || ENV["ADMIN_EMAIL"])&.strip
admin_password = (ENV["APP_ADMIN_PASSWORD"] || ENV["ADMIN_PASSWORD"])&.strip

# Strict Guard Gate: fail fast if account email is missing or placeholder
if admin_email.blank? || admin_email == "your-email@gmail.com" || admin_email == "your-personal-email@gmail.com"
  warn "\n❌ [db:seed ERROR] GOOGLE_CLOUD_ACCOUNT (or ADMIN_EMAIL) is not set in environment!".red rescue warn("\n❌ [db:seed ERROR] GOOGLE_CLOUD_ACCOUNT (or ADMIN_EMAIL) is not set in environment!")
  warn "   👉 You MUST set your Google account email address before seeding."
  warn "   - In local development: set GOOGLE_CLOUD_ACCOUNT=\"yourname@gmail.com\" in .env"
  warn "   - On Google Cloud Run: deploy with --set-env-vars GOOGLE_CLOUD_ACCOUNT=\"yourname@gmail.com\"\n"
  exit 1
end

admin_password = "Ch4ng3m3!!1" if admin_password.blank?

puts "* Adding/Updating Admin User: #{admin_email}"
admin_user = User.find_or_create_by!(email_address: admin_email) do |user|
  user.password = admin_password
  user.created_via = "seed"
  user.description = "Default seeded blog administrator."
end
admin_user.update!(created_via: "seed", description: "Default seeded blog administrator.") if admin_user.created_via.blank?

# In development or when explicitly requested, dispatch a password reset email via ActionMailer
# which will be intercepted locally by Mailpit on port 8025 (SMTP: 1025).
if Rails.env.development? || ENV["SEND_ADMIN_RESET_EMAIL"] == "true"
  puts "* Dispatching password reset email to #{admin_email} (Catch on Mailpit: http://localhost:8025)"
  PasswordsMailer.reset(admin_user).deliver_later rescue puts("  (Mailer skipped: #{$!.message})")
end

# --- Smart Environment & Stage Auto-Discovery (Issue #25 & Constitution §5) ---
adapter = ApplicationRecord.connection.adapter_name.to_s.downcase # 'sqlite' or 'postgresql'
is_postgres = adapter.include?("postgres")
is_cloud_run = ENV["K_SERVICE"].present? || ENV["RAILS8_ENV_LAUNCH_MODE"].to_s.downcase.include?("cloud run")
is_gcs = Rails.configuration.active_storage.service.to_s.start_with?("google")

# Explicit override takes precedence, otherwise auto-discover
detected_stage = if ENV["WORKSHOP_STEP"].present?
                   ENV["WORKSHOP_STEP"].to_i
                 elsif is_postgres
                   3 # Cloud SQL Persistent
                 elsif is_gcs
                   2 # Cloud Run with GCS storage
                 elsif is_cloud_run
                   1 # Cloud Run Ephemeral SQLite
                 else
                   0 # Localhost baseline
                 end

puts "* Detected Workshop Environment Stage: #{detected_stage} (Adapter: #{adapter}, Cloud Run: #{is_cloud_run}, GCS: #{is_gcs})"

# Narrative Storytelling Posts based on detected stage
case detected_stage
when 0 # Localhost baseline
  post = Post.find_or_create_by!(title: "[LOCAL BASELINE] Welcome to Rails 8 on Localhost!")
  post.update!(
    body: "Welcome to Step 2! You are running on local disk storage and local database. Outgoing emails are intercepted by Mailpit on http://localhost:8025.",
    updated_at: Time.zone.parse("2026-07-21 10:30:00")
  )
  sad_img = Rails.root.join("app", "assets", "images", "local_sad_image.png")
  if File.exist?(sad_img) && !post.cover_image.attached?
    post.cover_image.attach(io: File.open(sad_img), filename: "local_sad_image.png", content_type: "image/png")
  end
  post.comments.find_or_create_by!(content: "Localhost baseline up and running! 🚀", commenter_name: "Riccardo")

when 1 # Cloud Run Ephemeral
  post = Post.find_or_create_by!(title: "[EPHEMERAL] ⚠️ Welcome to Cloud Run Single Container!")
  post.update!(
    body: "You are currently deployed to Cloud Run with ephemeral SQLite on container disk. If this container restarts or scales to 0, all data in this database will vanish!",
    updated_at: Time.zone.parse("2026-07-21 10:35:00")
  )
  sad_img = Rails.root.join("app", "assets", "images", "local_sad_image.png")
  if File.exist?(sad_img) && !post.cover_image.attached?
    post.cover_image.attach(io: File.open(sad_img), filename: "local_sad_image.png", content_type: "image/png")
  end
  post.comments.find_or_create_by!(content: "Witness the Stateless Shock when you restart this service! ⚡", commenter_name: "Emiliano")

when 2 # Cloud Run + GCS Storage
  post = Post.find_or_create_by!(title: "[GCS PERSISTENT] ☁️ ActiveStorage Connected to Cloud Storage")
  post.update!(
    body: "Your media assets are now stored safely in a private Google Cloud Storage bucket with IAM Credentials signing (iam: true). Images will survive container restarts even while SQLite resets!",
    updated_at: Time.zone.parse("2026-07-21 10:40:00")
  )
  gcs_img = Rails.root.join("app", "assets", "images", "gcs_dev_image.jpg")
  if File.exist?(gcs_img) && !post.cover_image.attached?
    post.cover_image.attach(io: File.open(gcs_img), filename: "gcs_dev_image.jpg", content_type: "image/jpeg")
  end
  post.comments.find_or_create_by!(content: "Images are safe in GCS! Notice the stuck-jobs banner if you create background tasks without workers.", commenter_name: "Gemini")

when 3 # Cloud SQL Persistent
  post = Post.find_or_create_by!(title: "[CLOUD SQL PERSISTENT] 🐘 Connected to Google Cloud SQL!")
  post.update!(
    body: "Congratulations! Your application is connected to Google Cloud SQL PostgreSQL via the Cloud SQL Auth Proxy sidecar container. Full database persistence achieved!",
    updated_at: Time.zone.parse("2026-07-21 10:45:00")
  )
  gcs_img = Rails.root.join("app", "assets", "images", "gcs_dev_image.jpg")
  if File.exist?(gcs_img) && !post.cover_image.attached?
    post.cover_image.attach(io: File.open(gcs_img), filename: "gcs_dev_image.jpg", content_type: "image/jpeg")
  end
  post.comments.find_or_create_by!(content: "Canonical reference architecture active: Puma web + Solid Queue worker + Cloud SQL proxy sidecar! 🏆", commenter_name: "Riccardo")
end

puts "* Database seeding completed successfully for Stage #{detected_stage}."
