class NewestMigration

  def self.set_languages
    Newest.where(:prod_key => /^php\//i).update_all(        language: Product::A_LANGUAGE_PHP    )
    Newest.where(:prod_key => /^pip\//i).update_all(        language: Product::A_LANGUAGE_PYTHON )
    Newest.where(:prod_key => /^Node\//i).update_all(       language: Product::A_LANGUAGE_NODEJS )
    Newest.where(:prod_key => /^npm\//i).update_all(        language: Product::A_LANGUAGE_NODEJS )
    Newest.where(:prod_key => /^R\//i).update_all(          language: Product::A_LANGUAGE_R )
    Newest.where(:prod_key => /^JavaScript\//i).update_all( language: Product::A_LANGUAGE_JAVASCRIPT )
    Newest.where(:prod_key => /^Clojure\//i).update_all(    language: Product::A_LANGUAGE_CLOJURE )
    Newest.where(:prod_key => /^org\./i).update_all(        language: Product::A_LANGUAGE_JAVA )
    Newest.where(:prod_key => /^com\./i).update_all(        language: Product::A_LANGUAGE_JAVA )
    Newest.where(:prod_key => /^de\./i).update_all(         language: Product::A_LANGUAGE_JAVA )
    Newest.where(:prod_key => /^dom4j\./i).update_all(      language: Product::A_LANGUAGE_JAVA )
    Newest.where(:prod_key => /^[a-z]+\.[a-z]+\.[a-z]*/i).update_all( language: Product::A_LANGUAGE_JAVA )
    Newest.where(:prod_key => /^[a-z]+\.[a-z\.]+\/[a-z]+/i).update_all( language: Product::A_LANGUAGE_JAVA )
  end

  def self.set_languages_slow
    newests = Newest.where(:language => nil)
    newests.each do |newest|
      product = Product.find_by_key( newest.prod_key )
      if product.nil?
        newest.remove
        p "remove #{newest.prod_key}"
      else
        newest.language = product.language
        newest.save
      end
    end
  end

  def self.update_php_prod_keys
    elements = Newest.where(:prod_key => /^php\//i)
    elements.each do |element|
      element.prod_key = element.prod_key.gsub("php\/", "")
      element.save
    end
  end

end
