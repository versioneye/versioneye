class LanguageConstraint

  def matches?(request)
    path = request.path
    path = path[1..path.length]
    languages = distinct_languages
    languages << 'nodejs'
    languages.each do |lang|
      return true if /\A#{lang}\z/i =~ path || /\A#{lang}\/.*\z/i =~ path
      return true if path.match(/c\+\+/i)
    end
    false
  end

  private

    def distinct_languages
      key = "distinct_languages"
      languages = cached_languages key
      if languages.to_s.empty?
        languages = Product.all.distinct(:language)
        save_in_cache key, languages
      end
      languages
    end

    def cached_languages key
      Rails.cache.read key
    rescue => e
      Rails.logger.error e.message
      nil
    end

    def save_in_cache key, languages
      Rails.cache.write( key, languages, timeToLive: 1.hour )
    rescue => e
      Rails.logger.error e.message
      nil
    end

end
