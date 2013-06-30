class Newest

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name      , type: String
  field :version   , type: String
  field :language  , type: String
  field :prod_key  , type: String
  field :prod_type , type: String
  field :product_id, type: String


  def product
    Product.fetch_product self.language, self.prod_key
  end

  def self.get_newest( count )
    Newest.all().desc( :created_at ).limit( count )
  end

end
