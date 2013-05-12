class UserMigration

  def self.show_users_with_double_products 
    User.all.each do |user|
      if user.products.count != user['product_ids'].count
        Rails.logger.info "#{user.username} : #{user.products.count} : #{user['product_ids'].count}"
      end
    end
  end

  def self.remove_double_products 
    User.all.each do |user|
      if user.products.count != user['product_ids'].count
        Rails.logger.info user.username 
        products = Array.new( user.products )
        user.products.clear 
        products.each do |product|
          user.products.push product 
        end
      end
    end
  end

end
