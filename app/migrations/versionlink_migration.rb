class VersionlinkMigration

  def self.set_languages
    Versionlink.where(:prod_key => /^[a-z]+\.[a-z\.]+\/[a-z]+/i).update_all(      language: Product::A_LANGUAGE_JAVA )
    Versionlink.where(:prod_key => /^[0-9a-z]+[\-\.\_]+[0-9a-z]+\/[0-9a-z]+[\-\.\_]+[0-9a-z]+/i).update_all( language: Product::A_LANGUAGE_JAVA )
    Versionlink.where(:prod_key => /^[0-9a-z]+[\-\.\_]+[0-9a-z\-\.\_]+\/[0-9a-z\-\.\_]+/i).update_all( language: Product::A_LANGUAGE_JAVA )

    Versionlink.where(:link     => /rubygems\.org/i).update_all( language: Product::A_LANGUAGE_RUBY )
    Versionlink.where(:link     => /hibernate\.org/i).update_all(                 language: Product::A_LANGUAGE_JAVA )
    Versionlink.where(:link     => /maven\.springframework\.org/i).update_all(    language: Product::A_LANGUAGE_JAVA )
    Versionlink.where(:link     => /appfuse\.org/i).update_all(                   language: Product::A_LANGUAGE_JAVA )
    Versionlink.where(:link     => /repo\.jfrog\.org/i).update_all(               language: Product::A_LANGUAGE_JAVA )
    Versionlink.where(:link     => /repo\.typesafe\.com/i).update_all(            language: Product::A_LANGUAGE_JAVA )
    Versionlink.where(:link     => /repository\.jboss\.org/i).update_all(         language: Product::A_LANGUAGE_JAVA )
    Versionlink.where(:link     => /search\.maven\.org/i).update_all(             language: Product::A_LANGUAGE_JAVA )
    Versionlink.where(:link     => /gradle\.artifactoryonline\.com/i).update_all( language: Product::A_LANGUAGE_JAVA )
    Versionlink.where(:link     => /jakarta\.apache/i).update_all(                language: Product::A_LANGUAGE_JAVA )

    Versionlink.where(:prod_key => /^php\//i).update_all(        language: Product::A_LANGUAGE_PHP    )
    Versionlink.where(:prod_key => /^Python\//i).update_all(     language: Product::A_LANGUAGE_PYTHON )
    Versionlink.where(:prod_key => /^pip\//i).update_all(        language: Product::A_LANGUAGE_PYTHON )
    Versionlink.where(:prod_key => /^Node\//i).update_all(       language: Product::A_LANGUAGE_NODEJS )
    Versionlink.where(:prod_key => /^npm\//i).update_all(        language: Product::A_LANGUAGE_NODEJS )
    Versionlink.where(:prod_key => /^R\//i).update_all(          language: Product::A_LANGUAGE_R )
    Versionlink.where(:prod_key => /^JavaScript\//i).update_all( language: Product::A_LANGUAGE_JAVASCRIPT )
    Versionlink.where(:prod_key => /^Clojure\//i).update_all(    language: Product::A_LANGUAGE_CLOJURE )
    Versionlink.where(:prod_key => /^[0-9a-z\_\-]+$/i).update_all( language: Product::A_LANGUAGE_RUBY )
  end

  def self.set_languages_slow
    self.remove_nil_links
    self.remove_zip_links
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

  def self.update_php_prod_keys
    elements = Versionlink.where(:prod_key => /^php\//i)
    elements.each do |element|
      element.prod_key = element.prod_key.gsub("php\/", "")
      element.save
    end
  end

  def self.update_pip_prod_keys
    elements = Versionlink.where(:prod_key => /^pip\//i)
    elements.each do |element|
      element.prod_key = element.prod_key.gsub("pip\/", "")
      element.save
    end
  end

  def self.update_npm_prod_keys
    elements = Versionlink.where(:prod_key => /^npm\//i)
    elements.each do |element|
      element.prod_key = element.prod_key.gsub("npm\/", "")
      element.save
    end
  end

  private

    def self.remove_nil_links
      Versionlink.where(:link => nil).delete_all()
    rescue => e
      p e
    end

    def self.remove_zip_links
      Versionlink.where(:prod_key => /^php\//i, :name => /\.zip$/i).delete_all()
      Versionlink.where(:language => Product::A_LANGUAGE_PHP, :name => /\.zip$/i).delete_all()
    rescue => e
      p e
    end

end
