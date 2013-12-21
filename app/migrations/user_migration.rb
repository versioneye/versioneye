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

  def self.privacify
    User.all.each do |user|
      next if user.username.eql?('reiz')
      next if user.username.eql?('timgluz')
      next if user.username.eql?('rmetzler')
      random_value = create_random_value
      user.email = "test_#{random_value}@versioneye.com"
      user.save
    end
  end

  def self.create_random_value
      chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
      value = ''
      10.times { value << chars[rand(chars.size)] }
      value
    end

end
