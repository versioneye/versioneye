class StatisticService

  A_STAT_LANGUAGES = [
      Product::A_LANGUAGE_RUBY,
      Product::A_LANGUAGE_PYTHON,
      Product::A_LANGUAGE_NODEJS,
      Product::A_LANGUAGE_PHP,
      Product::A_LANGUAGE_JAVA,
      Product::A_LANGUAGE_R,
      Product::A_LANGUAGE_CLOJURE,
      Product::A_LANGUAGE_OBJECTIVEC
    ]

  def self.language_project_count
    json_cache = JsonCache.language_project_count
    if json_cache
      return eval json_cache.json_string
    else
      self.language_project_count_current
    end
  end

  def self.language_project_trend
    json_cache = JsonCache.language_project_trend
    if json_cache
      return eval json_cache.json_string
    else
      self.language_project_trend_current
    end
  end

  def self.update_all
    self.update_language_project_count
    self.update_language_project_trend
  end

  def self.update_language_project_count
    json_cache = JsonCache.language_project_count
    if json_cache.nil?
      json_cache = JsonCache.new({:name => JsonCache::A_LANGUAGE_PROJECT_COUNT})
    end
    json_cache.json_string = self.language_project_count_current().inspect()
    json_cache.save
  end

  def self.update_language_project_trend
    json_cache = JsonCache.language_project_trend
    if json_cache.nil?
      json_cache = JsonCache.new({:name => JsonCache::A_LANGUAGE_PROJECT_TREND})
    end
    json_cache.json_string = self.language_project_trend_current().inspect()
    json_cache.save
  end

  def self.language_project_count_current()
    data = []
    A_STAT_LANGUAGES.each do |lang|
      count = Product.where(language: lang).count
      data << [lang, count]
    end
    data
  end

  def self.language_project_trend_current(start_date = nil, end_date =  nil)
    # returns cumulative trend of languages of given period,
    # which by default is from 4th april to end of current month
    # Arguments have to Date object

    start_date = Date.new(2012, 4) if (start_date.nil? or not start_date.instance_of? Date)
    end_date = Date.today if (end_date.nil? or not end_date.instance_of? Date)
    results = []
    n_months = StatisticService.diff_in_months(start_date, end_date)

    n_months.times do |i|
      curr_date = start_date >> i
      stats = { date: curr_date.strftime('%Y-%m-%d')}
      A_STAT_LANGUAGES.each do |lang|
        ncount = Product.where(language: lang, created_at: {'$lt' => curr_date}).count
        encoded_lang = Product.encode_language(lang).to_s
        stats.merge!({encoded_lang => ncount})
      end

      results << stats
    end

    return results
  end

  def self.diff_in_months(date1, date2)
    (date2.year*12+date2.month) - (date1.year*12+date1.month)
  end

end
