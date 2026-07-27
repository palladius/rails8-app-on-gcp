class AddCommenterDetailsToComments < ActiveRecord::Migration[8.1]
  def change
    add_reference :comments, :user, null: true, foreign_key: true
    add_column :comments, :commenter_name, :string
  end
end
