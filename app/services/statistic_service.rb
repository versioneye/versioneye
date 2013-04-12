class StatisticService

  A_STAT_LANGUAGES = ["Java", "Ruby", "Python", "Node.JS", "Clojure", "R", "PHP"]

  
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
    results = {}
    xlabels = []
    first_run = true
    A_STAT_LANGUAGES.each do |lang|
      lang_vals = []
      i = 0
      iter_date = start_date
      while iter_date < end_date
        xlabels << "#{Date::ABBR_MONTHNAMES[iter_date.month]}/#{iter_date.year}" if first_run
        ncount = Product.where(language: lang, created_at: {"$lt" => iter_date}).count
        lang_vals << [i += 1, ncount]
        iter_date = iter_date >> 1
      end
      results[lang] = lang_vals.clone
      first_run = false;
    end    
    return {:xlabels => xlabels, :data => results}
  end

end