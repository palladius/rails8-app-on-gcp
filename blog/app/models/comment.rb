class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user, optional: true
  broadcasts_to :post

  def author_name
    return user.email_address.split("@").first.capitalize if user.present?
    return commenter_name if commenter_name.present?
    "Anonymous"
  end
end
