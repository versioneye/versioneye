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
      languages = Rails.cache.read key
      if languages.to_s.empty?
        languages = Product.all.distinct(:language)
        Rails.cache.write( key, languages, timeToLive: 1.hour )
      end
      languages
    end

end
