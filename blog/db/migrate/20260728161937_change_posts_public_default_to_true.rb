class ChangePostsPublicDefaultToTrue < ActiveRecord::Migration[8.1]
  def change
    change_column_default :posts, :public, from: false, to: true
    # Also flip existing posts to public
    Post.update_all(public: true)
  end
end
