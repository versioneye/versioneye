class DeveloperMigration

  def self.set_languages
    Developer.where(:prod_key => /^php\//i).update_all(        language: Product::A_LANGUAGE_PHP    )
    Developer.where(:prod_key => /^pip\//i).update_all(        language: Product::A_LANGUAGE_PYTHON )
    Developer.where(:prod_key => /^Node\//i).update_all(       language: Product::A_LANGUAGE_NODEJS )
    Developer.where(:prod_key => /^npm\//i).update_all(        language: Product::A_LANGUAGE_NODEJS )
    Developer.where(:prod_key => /^R\//i).update_all(          language: Product::A_LANGUAGE_R )
    Developer.where(:prod_key => /^JavaScript\//i).update_all( language: Product::A_LANGUAGE_JAVASCRIPT )
    Developer.where(:prod_key => /^Clojure\//i).update_all(    language: Product::A_LANGUAGE_CLOJURE )
    Developer.where(:prod_key => /^[0-9a-z\_\-]+$/i).update_all(           language: Product::A_LANGUAGE_RUBY )
    Developer.where(:prod_key => /^[a-z]+\.[a-z\.]+\/[a-z]+/i).update_all( language: Product::A_LANGUAGE_JAVA )
    Developer.where(:prod_key => /^[a-z]+\.[a-z\.]+\/[a-z]+/i).update_all( language: Product::A_LANGUAGE_JAVA )
    Developer.where(:prod_key => /^[0-9a-z]+[\-\.\_]+[0-9a-z]+\/[0-9a-z]+[\-\.\_]+[0-9a-z]+/i).update_all( language: Product::A_LANGUAGE_JAVA )
    Developer.where(:prod_key => /^[0-9a-z]+[\-\.\_]+[0-9a-z\-\.\_]+\/[0-9a-z]+[\-\.\_]+[0-9a-z\-\.\_]+/i).update_all( language: Product::A_LANGUAGE_JAVA )
    Developer.where(:prod_key => /^[0-9a-z]+[\-\.\_]+[0-9a-z\-\.\_]+\/[0-9a-z\-\.\_]+/i).update_all( language: Product::A_LANGUAGE_JAVA )
  end

  def self.set_languages_slow
    developers = Developer.where(:language => nil)
    developers.each do |developer|
      product = Product.find_by_key( developer.prod_key )
      if product.nil?
        # developer.remove
        p "developer without project: #{developer.prod_key} - #{developer.name}"
      else
        developer.language = product.language
        developer.save
      end
    end
  end

  def self.update_php_prod_keys
    elements = Developer.where(:prod_key => /^php\//i)
    elements.each do |element|
      element.prod_key = element.prod_key.gsub("php\/", "")
      element.save
    end
  end

end
