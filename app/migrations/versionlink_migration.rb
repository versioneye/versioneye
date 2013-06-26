class VersionlinkMigration

  def self.set_languages
    Versionlink.where(:prod_key => /^php/i).update_all(        language: Product::A_LANGUAGE_PHP    )
    Versionlink.where(:prod_key => /^Ruby/i).update_all(       language: Product::A_LANGUAGE_RUBY   )
    Versionlink.where(:prod_key => /^Python/i).update_all(     language: Product::A_LANGUAGE_PYTHON )
    Versionlink.where(:prod_key => /^pip/i).update_all(        language: Product::A_LANGUAGE_PYTHON )
    Versionlink.where(:prod_key => /^Node/i).update_all(       language: Product::A_LANGUAGE_NODEJS )
    Versionlink.where(:prod_key => /^npm/i).update_all(        language: Product::A_LANGUAGE_NODEJS )
    Versionlink.where(:prod_key => /^Java/i).update_all(       language: Product::A_LANGUAGE_JAVA )
    Versionlink.where(:prod_key => /^R/i).update_all(          language: Product::A_LANGUAGE_R )
    Versionlink.where(:prod_key => /^JavaScript/i).update_all( language: Product::A_LANGUAGE_JAVASCRIPT )
    Versionlink.where(:prod_key => /^Clojure/i).update_all(    language: Product::A_LANGUAGE_CLOJURE )
  end

  def self.set_languages_slow
    if Versionlink.where(:link => nil).count > 0
      Versionlink.where(:link => nil).remove()
    end
    links = Versionlink.where(:language => nil)
    links.each do |link|
      product = Product.find_by_key( link.prod_key )
      if product.nil?
        link.remove
        p "remove link : #{link.prod_key} - #{link.name} - #{link.link}"
      else
        link.language = product.language
        link.save
      end
    end
  end

end
