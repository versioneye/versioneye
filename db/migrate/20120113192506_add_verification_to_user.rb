class AddVerificationToUser < ActiveRecord::Migration
  def change
    add_column :users, :verification, :string
  end
end