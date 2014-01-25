class ProductService

  # languages have to be an array of strings.
  def self.search(q, group_id = nil, languages = nil, page_count = 1)
    EsProduct.search(q, group_id, languages, page_count)
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    Rails.logger.info  "Dam. We don't give up. Not yet! Start alternative search on awesome MongoDB."
    MongoProduct.find_by(q, '', group_id, languages, 300).paginate(:page => page_count)
  end


  def self.follow language, prod_key, user
    result = false
    product = Product.fetch_product language, prod_key
    product.users = Array.new if product && product.users.nil?
    if product && user && !product.users.include?( user )
      product.users.push user
      product.followers = 0 if product.followers.nil?
      product.followers += 1
      result = product.save
    end
    result
  end


  def self.unfollow language, prod_key, user
    result = false
    product = Product.fetch_product language, prod_key
    product.users = Array.new if product && product.users.nil?
    if product && user && product.users.include?( user )
      product.users.delete(user)
      product.followers = 0 if product.followers.nil?
      product.followers -= 1
      result = product.save
    end
    result
  end


  def self.updates_since_to(dt_since, dt_to)
    stats = []
    Product::A_LANGS_SUPPORTED.each do |lang|
      stats << {
        title: lang.downcase,
        value: Newest.where(:language => lang,
                            :created_at.gte => dt_since,
                            :created_at.lt => dt_to).count
      }
    end
    stats
  end


  def self.update_meta_data_global
    count = Product.count()
    page = 100
    iterations = count / page
    iterations += 1
    (0..iterations).each do |i|
      skip = i * page
      products = Product.all().skip(skip).limit(page)
      products.each do |product|
        VersionService.update_version_data( product, true )
        product.update_used_by_count( true )
        self.update_followers_for product
      end
    end
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  end

  def self.update_followers_for product
    return nil if product.followers == product.user_ids.count
    product.followers = product.user_ids.count
    product.save
  end

  def self.update_followers
    products = Product.where( :'user_ids.0' => {'$exists' => true} )
    products.each do |product|
      product.followers = product.users.count
      product.save
      Rails.logger.info "#{product.name} has #{product.followers} followers"
    end
    Rails.logger.info "#{products.count} products updated."
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

  def self.stats_last_month_releases
    month_ago = Date.today << 1
    to_stats_container(
      "Last month",
      updates_since_to(month_ago.at_beginning_of_month,
                       month_ago.at_end_of_month)
    )
  end
end
