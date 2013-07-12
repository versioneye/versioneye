class ProductService

  # languages have to be an array of strings.
  def self.search(q, group_id = nil, languages = nil, page_count = 1)
    EsProduct.search(q, group_id, languages, page_count)
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    Rails.logger.info  "Dam. We don't give up. Not yet! Start alternative search on awesome MongoDB."
    Product.find_by(q, "", group_id, languages, 300).paginate(:page => page_count)
  end


  def self.follow language, prod_key, user
    result = false
    product = Product.fetch_product language, prod_key
    if product && user && !product.users.include?( user )
      product.users.push user
      product.followers += 1
      result = product.save
    end
    result
  end


  def self.unfollow language, prod_key, user
    result = false
    product = Product.fetch_product language, prod_key
    if product && user && product.users.include?( user )
      product.users.delete(user)
      product.followers -= 1
      result = product.save
    end
    result
  end
 
  def self.updates_since_to(dt_since, dt_to)
    stats = []
    Product.supported_languages.each do |lang|
      stats << {
        title: lang.downcase,
        value: Product.all.where(:language => lang,
                                 :updated_at.gte => dt_since,
                                 :updated_at.lt => dt_to).count
      }
    end

    stats
  end
  
  def self.to_stats_container(title, stats)
    {
      title: title || "",
      total: stats.inject(0) {|acc, item| acc += item[:value]},
      values: stats
    }
  end

  def self.stats_today_releases
    dt_since = Date.today.at_midnight
    dt_to = DateTime.now
    to_stats_container("Today", updates_since_to(dt_since, dt_to))
  end

  def self.stats_yesterday_releases
    dt_since = 1.day.ago.at_midnight
    dt_to = Date.today.at_midnight
    to_stats_container("Yesterday", updates_since_to(dt_since, dt_to))
  end

  def self.stats_current_week_releases
    dt_since = Date.today.at_beginning_of_week
    dt_to = DateTime.now
    to_stats_container("Current week", updates_since_to(dt_since, dt_to))
  end

  def self.stats_current_month_releases
    dt_since = Date.today.at_beginning_of_month
    dt_to = DateTime.now
    to_stats_container("Current month", updates_since_to(dt_since, dt_to))
  end

  def self.stats_last_7days_releases
    dt_since = 7.days.ago.at_midnight
    dt_to = DateTime.now
    to_stats_container("Last 7 days", updates_since_to(dt_since, dt_to))
  end

  def self.stats_last_30days_releases
    dt_since = 30.days.ago.at_midnight
    dt_to = DateTime.now
    to_stats_container("Last 30 days", updates_since_to(dt_since, dt_to))
  end
end
