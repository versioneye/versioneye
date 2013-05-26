class CrawlerUtils

  def self.create_newest product, version_number
    newest = Newest.new
    newest.name = product.name
    newest.prod_key = product.prod_key
    newest.prod_type = product.prod_type
    newest.product_id = product._id.to_s
    newest.version = version_number
    newest.save
  end

  def self.create_notifications product, version_number
    new_notifications = 0
    followers = product.users
    return new_notifications if followers.nil? || followers.empty?
    followers.each do |follower|
      notification = Notification.new
      notification.user = follower
      notification.product = product
      notification.version_id = version_number
      if notification.save
        new_notifications += 1
      end
    end
    return new_notifications
  end

end
