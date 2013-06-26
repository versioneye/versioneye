class VersionarchiveMigration

  def self.set_languages
    Versionarchive.where(:prod_key => /^php/i).update_all(        language: Product::A_LANGUAGE_PHP    )
    Versionarchive.where(:prod_key => /^pip/i).update_all(        language: Product::A_LANGUAGE_PYTHON )
    Versionarchive.where(:prod_key => /^Node/i).update_all(       language: Product::A_LANGUAGE_NODEJS )
    Versionarchive.where(:prod_key => /^npm/i).update_all(        language: Product::A_LANGUAGE_NODEJS )
    Versionarchive.where(:prod_key => /^R/i).update_all(          language: Product::A_LANGUAGE_R )
    Versionarchive.where(:prod_key => /^JavaScript/i).update_all( language: Product::A_LANGUAGE_JAVASCRIPT )
    Versionarchive.where(:prod_key => /^Clojure/i).update_all(    language: Product::A_LANGUAGE_CLOJURE )

    Versionarchive.where(:name => /gem$/i).update_all(       language: Product::A_LANGUAGE_RUBY   )
    Versionarchive.where(:name => /jar$/i).update_all(       language: Product::A_LANGUAGE_JAVA )
    Versionarchive.where(:name => /pom$/i).update_all(       language: Product::A_LANGUAGE_JAVA )
  end

  def self.set_languages_slow
    archs = Versionarchive.where(:language => nil)
    archs.each do |arch|
      product = Product.find_by_key( arch.prod_key )
      if product.nil?
        arch.remove
        p "remove #{arch.prod_key} - #{arch.name}"
      else
        arch.language = product.language
        arch.save
      end
    end
  end

end
