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
Post.find_or_create_by!(title: "Welcome to our amazing Workshop") do |post|
  post.body = "Riccardo and Emiliano welcome you to this amazing Workshop!"
  post.updated_at = Time.zone.parse("2026-07-21 10:35:00")
end

welcome_post = Post.find_by(title: "Welcome to our amazing Workshop")
puts "* Adding 2 comments to the post"
welcome_post.comments.find_or_create_by!(content: "Riccardo: This is going to be an epic workshop! 🚀")
welcome_post.comments.find_or_create_by!(content: "Emiliano: Can't wait to show everyone the Cloud Run setup! ☁️")
