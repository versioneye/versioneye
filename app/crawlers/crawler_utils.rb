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
    log_exception e, logger
    false
  end

  def self.create_notifications(product, version_number, logger = nil)
    new_notifications = 0
    subscribers = product.users
    return new_notifications if subscribers.nil? || subscribers.empty?

    subscribers.each do |subscriber|
      success = create_notification( subscriber, product, version_number, logger )
      new_notifications += 1 if success
    end
    new_notifications
  rescue => e
    log_exception e, logger
    false
  end

  def self.create_notification user, product, version_number, logger
    notification            = Notification.new
    notification.user       = user
    notification.product    = product
    notification.version_id = version_number
    notification.save
  rescue => e
    log_exception e, logger
    false
  end

  def self.remove_version_prefix version_number
    if version_number && version_number.match(/v[0-9]+\..*/)
      version_number.gsub!('v', '')
    end
    if version_number && version_number.match(/r[0-9]+\..*/)
      version_number.gsub!('r', '')
    end
    if version_number && version_number.match(/php\-[0-9]+\..*/)
      version_number.gsub!('php-', '')
    end
    if version_number && version_number.match(/PHP\_[0-9]+\..*/)
      version_number.gsub!('PHP_', '')
    end
    version_number
  end

  private

    def self.log_exception e, logger = nil
      if logger
        logger.error e.message
        logger.error e.backtrace.join('\n')
      else
        p e.message
        p e.backtrace.join('\n')
      end
    end

end
