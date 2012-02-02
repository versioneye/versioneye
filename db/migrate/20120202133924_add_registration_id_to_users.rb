class AddRegistrationIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :registrationid, :string
  end
end