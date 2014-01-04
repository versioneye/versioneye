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
    return 'http://choosealicense.com/licenses/mit/' if mit_match( name )
    return 'http://www.ruby-lang.org/en/about/license.txt' if ruby_match( name )
    return 'http://www.apache.org/licenses/LICENSE-2.0.txt' if apache_license_2_match( name )
    return 'http://choosealicense.com/licenses/eclipse/' if eclipse_match( name )
    return 'http://opensource.org/licenses/gpl-2.0.php' if gpl_20_match( name )
    return 'http://opensource.org/licenses/artistic-license-1.0' if artistic_10_match( name )
    return 'http://opensource.org/licenses/artistic-license-2.0' if artistic_20_match( name )
    nil
  end

  def name_substitute
    return 'unknown' if name.to_s.empty?
    return 'MIT' if mit_match( name )
    return 'BSD' if bsd_match( name )
    return 'Ruby' if ruby_match( name )
    return 'GPL-2.0' if gpl_20_match( name )
    return 'Apache License, Version 2.0' if apache_license_2_match( name )
    return 'Apache License' if apache_license_match( name )
    return 'Eclipse Public License v1.0' if eclipse_match( name )
    return 'Artistic License 1.0' if artistic_10_match( name )
    return 'Artistic License 2.0' if artistic_20_match( name )
    name
  end

  def to_s
    "[License for(#{language}/#{prod_key}/#{version}) : #{name}]"
  end

  private

    def ruby_match name
      name.match(/^Ruby$/i) || name.match(/^Ruby License$/)
    end

    def mit_match name
      name.match(/^MIT$/i) || name.match(/^The MIT License$/) || name.match(/^MIT License$/)
    end

    def eclipse_match name
      name.match(/^Eclipse$/i) || name.match(/^Eclipse Public License v1\.0$/) || name.match(/^Eclipse License$/) || name.match(/^Eclipse Public License$/)
    end

    def bsd_match name
      name.match(/^BSD License$/i) || name.match(/^BSD$/) || name.match(/^MIT License$/)
    end

    def gpl_20_match name
      name.match(/^GPL\-2$/i) || name.match(/^GPL\-2\.0$/i)
    end

    def artistic_10_match name
      name.match(/^Artistic License 1\.0$/i) || name.match(/^Artistic License$/) || name.match(/^Artistic\-1\.0$/)
    end

    def artistic_20_match name
      name.match(/^Artistic License 2.0$/i) || name.match(/^Artistic 2.0$/)
    end

    def apache_license_match name
      name.match(/^Apache License$/i) || name.match(/^Apache Software Licenses$/i)
    end

    def apache_license_2_match name
      name.match(/^Apache License\, Version 2\.0$/i) ||
      name.match(/^Apache License Version 2\.0$/i) ||
      name.match(/^The Apache Software License\, Version 2\.0$/i) ||
      name.match(/^Apache 2$/i) ||
      name.match(/^Apache\-2$/i) ||
      name.match(/^Apache\-2\.0$/i) ||
      name.match(/^Apache 2\.0$/i) ||
      name.match(/^Apache License 2\.0$/i) ||
      name.match(/^Apache Software License - Version 2\.0$/i)
    end

end
