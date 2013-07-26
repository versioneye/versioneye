class NewestDailyCount
  include Mongoid::Document
  
  field :language, type: String
  field :date, type: DateTime
  field :value, type: Integer

  index(
    [:date, Mongo::DESCENDING],
    [
      [:date, Mongo::DESCENDING],
      [:language, Mongo::DESCENDING]
    ]
  )
 
  def self.inc_dummy_version(prod)
    latest_release = Newest.where(language: prod[:language], prod_key: prod[:prod_key]).desc(:created_at).first
    
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
    ndays.times do |nday|
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
          p "no dummy data for: #{prod[:prod_key]}"
        end
      end
    end
  end

  def self.update_counts
    if NewestDailyCount.all.count == 0 
      until_release_date = Newest.all.asc(:created_at).first[:created_at].to_date
    else
      until_release_date = NewestDailyCount.all.desc(:date).first[:date].to_date
    end
    
    ndays = (Date.today - until_release_date).numerator
    ndays.times do |n|
      #return if n > 30 #comment out if you want calc stats just for last 30 days
      lang_counts = ProductService.updates_since_to((n+1).days.ago.at_midnight,
                                                    n.days.ago.at_midnight)
      lang_counts.each {|row| NewestDailyCount.create!(language: row[:title], 
                                                       value: row[:value], 
                                                       date: n.days.ago.at_midnight)}
    end

    ndays
  end

  def self.to_response(t0_stats, t1_stats)
    rows = []
    changes = t0_stats.merge(t1_stats){|lang, oldval, newval| oldval - newval}
    t0_stats.each do |lang, val|
      rows << {title: lang, value: val, t1: changes[lang]}
    end
    rows.sort_by {|row| row[:title]}
  end
 
  def self.group_stats(rows)
    stats = {}
    rows.each do |row|
      stats[row[:language]] ||= 0
      stats[row[:language]] += row[:value]
    end

    stats
  end

  #-- query helpers

  def self.since_to(dt_since, dt_to, allow_grouping = true)
    rows = NewestDailyCount.where(:date.gte => dt_since,
                                  :date.lt => dt_to)
    allow_grouping ? self.group_stats(rows) : rows
  end
  
  def self.today_releases
    dt_since = Date.today.at_midnight
    dt_to = DateTime.now
    NewestDailyCount.since_to(dt_since, dt_to)
  end

  def self.yesterday_releases
    dt_since = 1.day.ago.at_midnight
    dt_to = Date.today.at_midnight
    NewestDailyCount.since_to(dt_since, dt_to)
  end
  def self.current_week_releases
    dt_since = Date.today.at_beginning_of_week
    dt_to = DateTime.now
    NewestDailyCount.since_to(dt_since, dt_to)
  end

  def self.last_week_releases
    dt_monday = Date.today.at_beginning_of_week
    dt_since = dt_monday.at_midnight - 7
    dt_to = dt_since.at_midnight
    NewestDailyCount.since_to(dt_since, dt_to)
  end

  def self.current_month_releases
    dt_since = Date.today.at_beginning_of_month
    dt_to = DateTime.now
    NewestDailyCount.since_to(dt_since, dt_to)
  end

  def self.last_30_days_releases(lang)
    today = Date.today
    NewestDailyCount.since_to(today - 30, today, false).where(language: lang)
  end

  def self.last_month_releases
    month_ago = Date.today << 1
    NewestDailyCount.since_to(month_ago.at_beginning_of_month,
                             month_ago.at_end_of_month)
  end
  
  def self.two_months_ago_releases
    two_months_ago = Date.today << 2
    NewestDailyCount.since_to(two_months_ago.at_beginning_of_month,
                              two_months_ago.at_end_of_month)
  end

  #-- response helpers

  def self.stats_today
    t0_stats = self.today_releases
    t1_stats = self.yesterday_releases
    self.to_response(t0_stats, t1_stats) 
  end

  def self.stats_current_week
    self.to_response(self.current_week_releases, self.last_week_releases)
  end

  def self.stats_current_month
    self.to_response(self.current_month_releases, self.last_month_releases)
  end

  def self.stats_last_month
    self.to_response(self.last_month_releases, self.two_months_ago_releases)
  end

  def self.language_30days_timeline(lang)
    rows = self.last_30_days_releases(lang)
    results = []
    rows.each {|row| results << {value: row[:value], date: row[:date].strftime('%Y-%m-%d')}}

    results
  end
end

