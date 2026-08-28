class AddDescriptionAndCreatedViaToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :description, :text
    add_column :users, :created_via, :string
  end
end
