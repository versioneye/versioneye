class Newest

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name      , type: String
  field :version   , type: String
  field :language  , type: String
  field :prod_key  , type: String
  field :prod_type , type: String
  field :product_id, type: String

  attr_accessible :name, :version, :language, :prod_key, :prod_type, :product_id, :created_at

  index(
    [
      [:updated_at, Mongo::DESCENDING]
    ],
    [
      [:updated_at, Mongo::DESCENDING],
      [:language, Mongo::DESCENDING]
    ])
  index(
    [
      [:updated_at, Mongo::DESCENDING]
    ],
    [
      [:updated_at, Mongo::DESCENDING],
      [:language, Mongo::DESCENDING]
    ])

  def product
    Product.fetch_product self.language, self.prod_key
  end

  def self.get_newest( count )
    Newest.all().desc( :created_at ).limit( count )
  end

  def self.balanced_newest(count)
    newest = []
    nlangs = Product.supported_languages.count
    if count > nlangs
      per_lang = (count / (nlangs * 1.0)).ceil
    else
      per_lang = count
    end

    Product.supported_languages.each do |lang|
      newest.concat Newest.where(language: lang).desc(:created_at).limit(per_lang)
    end
    newest.shuffle.first(count)
  end

end
