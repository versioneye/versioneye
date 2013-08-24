class LanguageDailyStats

  include Mongoid::Document
  include Mongoid::Timestamps

  field :date, type: DateTime
  field :date_string, type: String #format: %Y-%m-%d

  field :Clojure, type: Hash
  field :Java, type: Hash
  field :Javascript, type: Hash
  field :Nodejs, type: Hash
  field :Php, type: Hash
  field :Python, type: Hash
  field :R, type: Hash
  field :Ruby, type: Hash

  attr_accessible :language, :date, :metrics

  index(
    [:date, Mongo::DESCENDING],
    [:date, Mongo::DESCENDING]
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
    #metrics table for every language
    {
      "new_version" => 0,   #new versions publised
      "novel_package" => 0, #new libraries published
      "total_package" => 0, #total packages upto this date
      "total_artifact" => 0 #total artifacts upto this date
    }
  end

  def self.update_counts(ndays = 1)
    ndays.times do |n|
      Rails.logger.debug("Counting language_daily_stats: #{n + 1} / #{ndays}")
      self.update_day_stats(n)
    end
  end

  def initialize_metrics_tables
    Product.supported_languages.each do |lang|
      lang_key = LanguageDailyStats.language_to_sym(lang)
      self[lang_key] = LanguageDailyStats.initial_metrics_table
    end
  end

  def self.language_to_sym(lang)
    Product.encode_language(lang).capitalize.to_sym
  end

  def self.to_date_string(that_day)
    that_day.strftime("%Y-%m-%d")
  end

  def self.new_document(that_day, save = false)
    day_string = self.to_date_string(that_day)
    self.where(date_string: day_string).delete_all #remove previous  document

    new_doc  = self.new date: that_day.at_midnight
    new_doc[:date_string] = self.to_date_string(that_day)
    new_doc.initialize_metrics_tables
    
    new_doc.save if save
    new_doc
  end

  def self.update_day_stats( n )
    that_day = n.days.ago.at_beginning_of_day
    that_day_doc = self.new_document(that_day, true)
    that_day_doc.count_releases
    that_day_doc.count_language_packages
    that_day_doc.count_language_artifacts
  end

  def count_releases
    that_day = self[:date]
    that_day_releases = Newest.since_to(that_day.at_midnight, (that_day + 1.day).at_midnight)
    return if that_day_releases.nil?

    that_day_releases.each do |release|
      self.count_release(release)
    end
  end

  def count_release(release)
    if Product.supported_languages.include?(release[:language])
      prod_info = Product.fetch_product(release[:language], release[:prod_key])
      metric_key = LanguageDailyStats.language_to_sym(release[:language])

      self.inc_version(metric_key)
      self.inc_novel(metric_key) if LanguageDailyStats.novel?(release, prod_info)
    else
      Rails.logger.error("Product #{release[:prod_key]} misses language or language are not supported.")
    end
  end

  def count_language_packages
    that_day = self[:date]
    Product.supported_languages.each do |lang|
      lang_total = Product.by_language(lang).where(:created_at.lt => that_day.at_midnight).count
      language_key = LanguageDailyStats.language_to_sym(lang)
      self.inc_total_package(language_key, lang_total)
    end
  end

  def count_language_artifacts
    that_day = self[:date]
    Product.supported_languages.each do |lang|
      n_artifacts = 0
      Product.by_language(lang).where(:created_at.lt => that_day.at_midnight).each do |prod|
        n_artifacts += prod.versions.where(:created_at.lt => that_day.at_midnight).count
      end

      language_key = LanguageDailyStats.language_to_sym(lang)
      self.inc_total_artifact(language_key, n_artifacts)
    end
  end

  def inc_version(metric_key, val = 1)
     self.inc("#{metric_key}.new_version", val)
  end

  def inc_novel(metric_key, val =  1)
    self.inc("#{metric_key}.novel_package", val)
  end

  def inc_total_package(metric_key, val =  1)
    self.inc("#{metric_key}.total_package", val)
  end

  def inc_total_artifact(metric_key, val = 1)
    self.inc("#{metric_key}.total_artifact", val)
  end

  def self.novel?( release_info, prod_info)
    if release_info.nil? or prod_info.nil?
      return false
    end

    if release_info.attributes.has_key?(:created_at) and release_info.attributes.has_key?(:created_at)
      product_date = self.to_date_string(prod_info[:created_at])
      release_date = self.to_date_string(release_info[:created_at])
      return release_date == product_date
    end

    false
  end

  def metrics
    doc = self.attributes
    langs_keys = []
    Product.supported_languages.each {|lang| langs_keys << LanguageDailyStats.language_to_sym(lang)}
    doc.keep_if {|key, val| langs_keys.include?(key.to_sym)}
  end
  
  #shows only metrics of Stats doc 
  def self.doc_metrics(doc)
    if doc.nil?
      Rails.logger.warn("It tried to read not existing todays stat - returning new empty doc.")
      doc = self.new_document(Date.today)
    end  
    doc.metrics
  end

  def self.combine_docs(docs)
    stats = {}
    docs.each do |doc|
      doc_stats = LanguageDailyStats.doc_metrics(doc)
      stats.merge!(doc_stats) do |lang_key, doc1, doc2|
        doc1 ||= {}
        doc1.merge(doc2) {|metric, oldval, newval| oldval + newval}
      end
    end

    stats
  end

  #-- query helpers
  def self.latest_stats
    doc = self.all.last
    self.doc_metrics(doc)
  end

  def self.since_to(dt_since, dt_to)
    self.where(:date.gte => dt_since, :date.lt => dt_to).desc(:date)
  end

  def self.today_stats
    dt_string = LanguageDailyStats.to_date_string(Date.today)
    doc = self.where(date_string: dt_string).shift
    self.doc_metrics(doc)
  end

  def self.yesterday_stats
    dt_string = LanguageDailyStats.to_date_string(1.day.ago)
    doc = self.where(date_string: dt_string).shift
    self.doc_metrics(doc)
  end

  def self.current_week_stats
    dt_since = Date.today.at_beginning_of_week
    dt_to    = DateTime.now
    rows = self.since_to(dt_since, dt_to)
    self.combine_docs(rows)
  end

  def self.last_week_stats
    dt_monday      = Date.today.at_beginning_of_week
    dt_prev_monday = dt_monday - 7
    rows = self.since_to(dt_prev_monday, dt_monday)
    self.combine_docs(rows)
  end


  def self.current_month_stats
    dt_since = Date.today.at_beginning_of_month
    dt_to    = DateTime.now
    rows = self.since_to(dt_since, dt_to)
    self.combine_docs(rows)
  end

  def self.last_30_days_stats
    self.since_to(15.days.ago.at_midnight, Date.tomorrow.at_midnight).asc(:date)
  end

  def self.last_month_stats
    month_ago = Date.today << 1
    rows      = self.since_to(month_ago.at_beginning_of_month, Date.today.at_beginning_of_month)
    self.combine_docs(rows)
  end

  def self.two_months_ago_stats
    month_ago      = Date.today << 1
    two_months_ago = Date.today << 2
    rows           = self.since_to(two_months_ago.at_beginning_of_month, month_ago.at_beginning_of_month)
    self.combine_docs(rows)
  end

  #-- response helpers

  def self.to_metric_response(metric, t0_stats, t1_stats)
    rows = []

    Product.supported_languages.each do |lang|
      lang_key = LanguageDailyStats.language_to_sym(lang).to_s

      t0_metric_value = t0_stats[lang_key][metric] if t0_stats.has_key?(lang_key)
      t1_metric_value = t1_stats[lang_key][metric] if t1_stats.has_key?(lang_key)
      if t0_metric_value and t1_metric_value
        diff = t0_metric_value - t1_metric_value
      else
        diff  = 0
      end

      rows << {
        title: lang,
        value: t0_metric_value || 0,
        t1: diff
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
    rows = self.last_30_days_stats
    results = []
    return results if rows.nil?

    lang_key = LanguageDailyStats.language_to_sym(lang)
    rows.each do |row|
      results << {
        title: lang,
        value: row[lang_key][metric],
        date: row[:date_string]
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

