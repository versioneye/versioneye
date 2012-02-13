class AddNotificationToFollowers < ActiveRecord::Migration
  def change
    add_column :followers, :notification, :boolean
  end
end
