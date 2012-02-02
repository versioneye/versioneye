class RemoveRegistrationIdFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :registrationid
  end
end
