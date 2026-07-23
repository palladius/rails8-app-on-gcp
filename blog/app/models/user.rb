class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Gravatar avatar URL based on email hash
  def gravatar_url(size: 80)
    hash = Digest::MD5.hexdigest(email_address.strip.downcase)
    "https://www.gravatar.com/avatar/#{hash}?s=#{size}&d=retro"
  end
end
