# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# User.create!(email_address: "<YOUR EMAIL ADDRESS>", password: "<YOUR PASSWORD>")

puts "* Adding user TODO EMAIL_ADDRESS"
User.find_or_create_by!(email_address: "riccardo@example.com") do |user|
  user.password = "Ch4ng3m3!!1"
end

puts "* Adding a post"
welcome_post = Post.find_or_create_by!(title: "Welcome to our amazing Workshop (with pic)")
welcome_post.update!(
  body: "This post was added by `rake db:seed` and proves this image is attached and configured correctly in GCS:",
  updated_at: Time.zone.parse("2026-07-21 10:35:00")
)

# Attach test image for end-to-end ActiveStorage GCS verification
# Attach test image for end-to-end ActiveStorage GCS verification
env_short = { "development" => "dev", "test" => "test", "production" => "prod" }[Rails.env] || Rails.env
image_name = "gcs_#{env_short}_image.jpg"
image_path = Rails.root.join("app", "assets", "images", image_name)

if File.exist?(image_path) && !welcome_post.cover_image.attached?
  puts "* Attaching #{image_name} to the welcome post from pre-uploaded GCS object"

  welcome_post.cover_image.attach(
    io: File.open(image_path),
    filename: image_name,
    content_type: "image/jpeg"
  )

  welcome_post.comments.find_or_create_by!(content: "Do you like my cover image?!?", commenter_name: "Gemini")
else
  puts "* Issues with image / GCS"
  welcome_post.comments.find_or_create_by!(content: "Woopsie - no GCS images I'm afraid", commenter_name: "Gemini")
end

puts "* Adding a local post"
local_post = Post.find_or_create_by!(title: "Localhost only: The tragicomical tale")
local_post.update!(
  body: "This post proves that local file attachment still works. This poor creature is very sad but at least has a cover image now!",
  updated_at: Time.zone.parse("2026-07-21 10:40:00")
)

local_image_name = "local_sad_image.png"
local_image_path = Rails.root.join("app", "assets", "images", local_image_name)

if File.exist?(local_image_path) && !local_post.cover_image.attached?
  puts "* Attaching #{local_image_name} to the local post as cover_image"
  local_post.cover_image.attach(
    io: File.open(local_image_path),
    filename: local_image_name,
    content_type: "image/png"
  )
end

puts "* Adding 2 comments to the post"
welcome_post.comments.find_or_create_by!(content: "This is going to be an epic workshop! 🚀", commenter_name: "Riccardo")
welcome_post.comments.find_or_create_by!(content: "Can't wait to show everyone the Cloud Run setup! ☁️", commenter_name: "Emiliano")
