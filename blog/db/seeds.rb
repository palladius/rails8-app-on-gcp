# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

#User.create!(email_address: "<YOUR EMAIL ADDRESS>", password: "<YOUR PASSWORD>")

puts "* Adding user TODO EMAIL_ADDRESS"
User.find_or_create_by!(email_address: "riccardo@example.com") do |user|
  user.password = "Ch4ng3m3!!1"
end

puts "* Adding a post"
welcome_post = Post.find_or_create_by!(title: "Welcome to our amazing Workshop")
welcome_post.update!(
  body: "This post was added by `rake db:seed` and proves this image is attached and configured correctly in GCS:",
  updated_at: Time.zone.parse("2026-07-21 10:35:00")
)

# Attach test image for end-to-end ActiveStorage GCS verification
# Attach test image for end-to-end ActiveStorage GCS verification
image_name = "gcs_#{Rails.env}_image.jpg"
image_path = Rails.root.join("app", "assets", "images", image_name)

if File.exist?(image_path) && !welcome_post.cover_image.attached?
  puts "* Attaching #{image_name} to the welcome post from pre-uploaded GCS object"
  
  blob = ActiveStorage::Blob.find_or_create_by!(key: "seeds/#{image_name}") do |b|
    b.filename = image_name
    b.content_type = "image/jpeg"
    b.byte_size = File.size(image_path)
    b.checksum = Digest::MD5.file(image_path).base64digest
  end
  
  welcome_post.cover_image.attach(blob)
end

puts "* Adding 2 comments to the post"
welcome_post.comments.find_or_create_by!(content: "Riccardo: This is going to be an epic workshop! 🚀")
welcome_post.comments.find_or_create_by!(content: "Emiliano: Can't wait to show everyone the Cloud Run setup! ☁️")
