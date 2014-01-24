class LanguageConstraint

  def matches?(request)
    path = request.path
    path = path[1..path.length]
    languages = Product::A_LANGS_ALL
    languages << "nodejs"
    Product::A_LANGS_ALL.each do |lang|
      return true if path.match(/^#{lang}$/i) || path.match(/^#{lang}\/$/i)
    end
    false
  end

end
