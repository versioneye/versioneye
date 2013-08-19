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

end
