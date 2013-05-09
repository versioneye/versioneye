class UserMigration

  def self.migrate_followers
    users = User.all 
    count = 0 
    users.each do |user|
      products = user.fetch_my_products
      products.each do |product| 
        user.products.push product 
        count += 1
      end
      p count 
    end
  end

end
