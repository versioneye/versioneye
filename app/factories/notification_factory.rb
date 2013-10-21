class NotificationFactory

  def self.create_new(user = nil, save = true)
    user = UserFactory.create_new if user.nil?
    random_product = Product.random_product
    new_message = Notification.new  user_id: user.id,
                                    product_id: random_product.id,
                                    version_id: random_product.versions.last.id,
                                    version: random_product.version
    if save
      unless new_message.save
        p new_message.errors.full_messages.to_sentence
      end
    end

    new_message
  end
  
  def self.create_new_for_user_project(user = nil, save = true)
    user = UserFactory.create_new if user.nil?
    prod1 = Project.by_user(user).first.dependencies.to_a.sample
    random_product = Product.fetch_product(prod1[:language], prod1[:prod_key])
    new_message = Notification.new  user_id: user.id,
                                    product_id: random_product.id,
                                    version_id: random_product.versions.last.id,
                                    version: random_product.version
    if save
      unless new_message.save
        p new_message.errors.full_messages.to_sentence
      end
    end

    new_message
  end


end
