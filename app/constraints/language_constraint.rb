class LanguageConstraint

  def matches?(request)
    path = request.path
    path = path[1..path.length]
    languages = Product.all.distinct(:language)
    languages << "nodejs"
    languages.each do |lang|
      return true if path.match(/^#{lang}$/i) || path.match(/^#{lang}\/.*$/i)
    end
    false
  end

end
