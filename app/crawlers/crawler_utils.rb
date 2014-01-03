class CrawlerUtils

  def self.create_newest( product, version_number, logger = nil )
    newest = Newest.fetch_newest( product.language, product.prod_key, version_number )
    return nil if newest
    newest = Newest.new
    newest.name       = product.name
    newest.language   = product.language
    newest.prod_key   = product.prod_key
    newest.version    = version_number
    newest.prod_type  = product.prod_type
    newest.product_id = product._id.to_s
    newest.save
  rescue => e
    if logger
      logger.error "Error in CrawlerUtils.create_newest. #{e.message}"
      logger.error e.backtrace.join('\n')
    else
      p e.backtrace.join('\n')
    end
    false
  end

  def self.create_notifications(product, version_number, logger = nil)
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
    new_notifications
  rescue => e
    if logger
      logger.error "Error in CrawlerUtils.create_notifications. #{e.message}"
      logger.error e.backtrace.join('\n')
    else
      p e.backtrace.join('\n')
    end
    false
  end

end
