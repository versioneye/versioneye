class CrawlerUtils

  def self.create_newest product, version_number
    results = Newest.where(:language => product.language, :prod_key => product.prod_key, :version => version_number)
    return nil if results && !results.empty?
    newest = Newest.new
    newest.name       = product.name
    newest.language   = product.language
    newest.prod_key   = product.prod_key
    newest.version    = version_number
    newest.prod_type  = product.prod_type
    newest.product_id = product._id.to_s
    newest.save
  end

  def self.create_notifications product, version_number
    new_notifications = 0
    subscribers = product.users
    return new_notifications if subscribers.nil? || subscribers.empty?
    subscribers.each do |subscriber|
      notification            = Notification.new
      notification.user       = subscriber
      notification.product    = product
      notification.version = version_number
      if notification.save
        new_notifications += 1
      end
    end
    return new_notifications
  end

end
