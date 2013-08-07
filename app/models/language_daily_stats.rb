class LanguageDailyStats

  include Mongoid::Document
  include Mongoid::Timestamps

  field :language, type: String
  field :date, type: DateTime
  field :metrics, type: Hash
  field :novel, type: Boolean, default: false

  attr_accessible :language, :date, :metrics

  index(
    [:date, Mongo::DESCENDING],
    [
      [:date, Mongo::DESCENDING],
      [:language, Mongo::DESCENDING]
    ]
  )

  def self.inc_dummy_version(prod)
    latest_release = Newest.where(
      language: prod[:language],
      prod_key: prod[:prod_key]).desc(:created_at).first

    unless latest_release.nil?
      version_numbers = latest_release[:version].to_s.split(".")
    else
      version_numbers = prod[:version].to_s.split(".")
    end

    version_numbers = ["1"] if version_numbers.empty?

    updated_last_number = version_numbers.slice!(-1).to_i + 1
    version_numbers.push(updated_last_number)
    version_numbers = version_numbers.join('.')
    version_numbers += "-dummy" if version_numbers == prod[:version]
    version_numbers
  end

  def self.make_dummy_data(ndays = 60, prod_per_day = 100)
    (ndays+1).times do |nday|
      prod_per_day.times do |nprod|
        prod = Product.random_product
        newest = Newest.new({
          name: prod[:name],
          language: prod[:language],
          version: self.inc_dummy_version(prod),
          prod_key: prod[:prod_key],
          prod_type: prod[:prod_type],
          product_id: prod[:_id].to_s,
          created_at: (ndays - nday).days.ago #start from oldest to keep version numbers incremental
        })
        begin
          newest.save
        rescue
          p "no dummy data for: #{prod[:prod_key]} - #{newest.errors.full_messages.to_sentence}"
        end
      end
    end
  end

  def self.initial_metrics_table
    {
      "new_version" => 0,
      "novel_package" => 0,
    }
  end

  def self.get_or_create_doc(language, date, clean_prev_metrics = false)
    date_at = date.at_midnight
    stats_doc = self.where(language: language, date: date_at).first
    if stats_doc.nil? or clean_prev_metrics
      Rails.logger.debug("Created new language stats doc: #{language}:#{date_at}")
      stats_doc = self.new language: language,
                           date: date_at,
                           metrics: self.initial_metrics_table()
      stats_doc.save!
    end
    stats_doc
  end

  def self.get_language_stats(date, clean_prev_metrics = false)
    stats = {}
    Product.supported_languages.each do |lang|
      stats[lang] = self.get_or_create_doc(lang, date, clean_prev_metrics)
    end
    stats
  end

  def self.metric_last_updated_time(metric)
    until_release_date = Date.tomorrow
    if self.all.count == 0 and Newest.all.count > 0
      Rails.logger.debug("Going to add metrics for all updates")
      until_release_date = Newest.all.asc(:created_at).first[:created_at]
    elsif self.all.count > 0
      row = self.where(:"metrics.#{metric}".gt =>  0).desc(:date).first
      until_release_date = row[:date] unless row.nil?
      Rails.logger.debug("Going to add metrics only for last #{Date.today - until_release_date.to_date} days")
    end
    until_release_date.at_midnight.to_date
  end

  def self.metric_not_updated_in_days(metric)
    until_release_date = self.metric_last_updated_time(metric)
    ndays = (Date.today - until_release_date).numerator + 1
    ndays
  end

  def self.reset_day_stat_metrics(day_stats, metric)
    day_stats.each {|lang, row| row.update_attribute("metrics.#{metric}", 0) }
  end

  def self.update_counts
    ndays = self.metric_not_updated_in_days('new_version')
    latest_products = Product.where(:created_at.gte => ndays.ago.at_midnight)
    ndays.times do |n|
      self.process_something
    end
  end

  def self.update_count_for_one_day( n, latest_products )
    Rails.logger.debug("Counting language_daily_stats: #{n + 1}/#{ndays}")
    that_day = n.days.ago.at_beginning_of_day

    that_day_stats = self.get_language_stats(that_day)
    if that_day == Date.today
      #clean previous countings for today to prevent double counting
      that_day_stats = self.reset_day_stat_metrics(that_day_stats, 'new_version')
      that_day_stats = self.reset_day_stat_metrics(that_day_stats, 'novel_package')
    end

    that_day_releases = Newest.since_to(n.days.ago.at_midnight, (n-1).days.ago.at_midnight)
    next if that_day_releases.nil?

    self.process_day_releases( that_day_releases, that_day_stats )
  end

  def self.process_day_releases( that_day_releases, that_day_stats )
    that_day_releases.each do |row|
      prod_info = latest_products.where(language: row[:language], prod_key: row[:prod_key]).asc(:created_at).first

      is_released_on_same_day = self.fetch_released_on_day( prod_info )

      if that_day_stats.has_key?(row[:language])
        self.update_row( row, that_day_stats, is_released_on_same_day )
      end
    end
  end

  def self.update_row( row, that_day_stats, is_released_on_same_day )
    that_day_stats[row[:language]].inc("metrics.new_version", 1)
    if is_released_on_same_day
      #TODO: find better stragegy - super slow!!
      that_day_stats[row[:language]].inc("metrics.novel_package", 1)
      row.update_attribute(:novel, true)
      p "."
    end
  rescue
    msg =  "Failed to update counts for #{row.to_json} - probably misses language"
    Rails.logger.error(msg)
    p msg
  end

  def self.fetch_released_on_day( prod_info )
    return (prod_info[:created_at].at_midnight ==  row[:created_at].at_midnight) if prod_info
    return false if prod_info.nil?
  end

  #-- query helpers

  def self.group_by_language(rows)
    stats = {}
    rows.each do |row|
      stats[row[:language]] ||= self.initial_metrics_table
      stats[row[:language]].merge!(row.metrics) {|key, oldval, newval| oldval + newval}
    end

    stats
  end

  def self.since_to(dt_since, dt_to)
    self.where(:date.gte => dt_since, :date.lt => dt_to).desc(:date)
  end

  def self.today_stats
    dt_since = Date.today.at_midnight
    dt_to = DateTime.now
    rows = self.since_to(dt_since, dt_to)
    self.group_by_language(rows)
 end

  def self.yesterday_stats
    dt_since = 1.day.ago.at_midnight
    dt_to = Date.today.at_midnight
    rows = self.since_to(dt_since, dt_to)
    self.group_by_language(rows)
 end
  def self.current_week_stats
    dt_since = Date.today.at_beginning_of_week
    dt_to = DateTime.now
    rows = self.since_to(dt_since, dt_to)
    self.group_by_language(rows)
  end

  def self.last_week_stats
    dt_monday = Date.today.at_beginning_of_week
    dt_prev_monday = dt_monday - 7
    rows = self.since_to(dt_prev_monday, dt_monday)
    self.group_by_language(rows)
  end

  def self.current_month_stats
    dt_since = Date.today.at_beginning_of_month
    dt_to = DateTime.now
    rows = self.since_to(dt_since, dt_to)
    self.group_by_language(rows)
  end

  def self.last_30_days_stats(lang)
    self.since_to(30.days.ago.at_midnight, Date.tomorrow.at_midnight).where(language: lang).asc(:date)
  end

  def self.last_month_stats
    month_ago = Date.today << 1
    rows = self.since_to(month_ago.at_beginning_of_month, Date.today.at_beginning_of_month)
    self.group_by_language(rows)
  end

  def self.two_months_ago_stats
    month_ago = Date.today << 1
    two_months_ago = Date.today << 2
    rows = self.since_to(two_months_ago.at_beginning_of_month, month_ago.at_beginning_of_month)
    self.group_by_language(rows)
  end

  #-- response helpers

  def self.to_metric_response(metric, t0_stats, t1_stats)
    rows = []

    Product.supported_languages.each do |lang|
      t0_metric_value = 0
      t1_metric_value = 0

      t0_metric_value = t0_stats[lang][metric] if t0_stats.has_key?(lang)
      t1_metric_value = t1_stats[lang][metric] if t1_stats.has_key?(lang)

      rows << {
        title: lang,
        value: t0_metric_value,
        t1: t0_metric_value - t0_metric_value
      }
    end
    rows.sort_by {|row| row[:title]}
  end

  def self.get_time_span(time_span)
    case time_span
    when :today
      t1 = self.today_stats
      t2 = self.yesterday_stats
    when :current_week
      t1 = self.current_week_stats
      t2 = self.last_week_stats
    when :current_month
      t1 = self.current_month_stats
      t2 = self.last_month_stats
    when :last_month
      t1 = self.last_month_stats
      t2 = self.two_months_ago_stats
    end

    return t1, t2
  end

  def self.latest_versions(time_span)
    t1, t2 = get_time_span(time_span)
    self.to_metric_response('new_version', t1, t2)
  end

  def self.novel_releases(time_span)
    t1, t2 = get_time_span(time_span)
    self.to_metric_response('novel_package', t1, t2)
  end

  def self.language_timeline30(lang, metric)
    rows = self.last_30_days_stats(lang)
    results = []
    return results if rows.nil?

    rows.each do |row|
      results << {
        value: row["metrics"][metric],
        date: row[:date].strftime('%Y-%m-%d')
      }
    end
    results
  end

  def self.versions_timeline30(lang)
    self.language_timeline30(lang, 'new_version')
  end

  def self.novel_releases_timeline30(lang)
    self.language_timeline30(lang, 'novel_package')
  end
end

