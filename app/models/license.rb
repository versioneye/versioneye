class License

  include Mongoid::Document
  include Mongoid::Timestamps

  # This license belongs to the product with this attributes
  field :language     , type: String
  field :prod_key     , type: String
  field :version      , type: String

  field :name         , type: String # For example MIT
  field :url          , type: String # URL to the license text
  field :comments     , type: String # Maven specific
  field :distributions, type: String # Maven specific

  def product
    Product.fetch_product(self.language, self.prod_key)
  end

  def self.for_product( product, ignore_version = false )
    if ignore_version
      return License.where(:language => product.language, :prod_key => product.prod_key)
    else
      return License.where(:language => product.language, :prod_key => product.prod_key, :version => product.version)
    end
  end

  def link
    return url if url && !url.empty?
    return "http://choosealicense.com/licenses/mit/" if mit_match( name )
    return "http://www.apache.org/licenses/LICENSE-2.0.txt" if apache_license_2_match( name )
    nil
  end

  def name_substitute
    return "MIT" if mit_match( name )
    return "Apache License, Version 2.0" if apache_license_2_match( name )
    return "Apache License" if apache_license_match( name )
    name
  end

  def to_s
    "[License for(#{language}/#{prod_key}/#{version}) : #{name}]"
  end

  private

    def mit_match name
      name.match(/^MIT$/i) || name.match(/^The MIT License$/) || name.match(/^MIT License$/)
    end

    def apache_license_2_match name
      name.match(/^Apache License\, Version 2\.0$/i) || name.match(/^Apache License Version 2\.0$/i) || name.match(/^The Apache Software License\, Version 2\.0$/i)
    end

    def apache_license_match name
      name.match(/^Apache License$/i) || name.match(/^Apache Software Licenses$/i)
    end



end
