class AddPrivacyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :privacy_products, :string, :default => 'everybody'
    add_column :users, :privacy_comments, :string, :default => 'everybody'
  end
end