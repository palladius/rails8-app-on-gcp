class Post < ApplicationRecord
  has_rich_text :body
  has_one_attached :cover_image
  has_many :comments, dependent: :destroy
end
