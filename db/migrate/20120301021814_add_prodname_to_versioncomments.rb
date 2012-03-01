class AddProdnameToVersioncomments < ActiveRecord::Migration
  def change
    add_column :versioncomments, :prod_name, :string, :default => 'product name'
  end
end
