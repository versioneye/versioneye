class LanguageConstraint

  def matches?(request)
    path = request.path
    path = path[1..path.length]
    languages = LanguageService.distinct_languages
    languages << 'nodejs'
    languages.each do |lang|
      return true if /\A#{lang}\z/i =~ path || /\A#{lang}\/.*\z/i =~ path
      return true if path.match(/c\+\+/i)
    end
    false
  end

end
