class License

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name         , type: String
  field :url          , type: String
  field :comments     , type: String
  field :distributions, type: String

  # This license belongs to the product with this attributes
  field :language     , type: String
  field :prod_key     , type: String
  field :version      , type: String

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
    return "http://choosealicense.com/licenses/mit/" if name.match(/^#{name}$/i)
    return nil
  end

end
