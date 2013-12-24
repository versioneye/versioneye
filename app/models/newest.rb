class Newest

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name      , type: String
  field :version   , type: String
  field :language  , type: String
  field :prod_key  , type: String
  field :prod_type , type: String
  field :product_id, type: String

  scope :by_language, ->(lang){where(language: lang)}

  attr_accessible :name, :version, :language, :prod_key, :prod_type, :product_id, :created_at

  index({updated_at: -1}, {background: true})
  index({updated_at: -1, language: -1}, {background: true})
  index({language: 1, prod_key: 1, version: 1}, { unique: true , background: true})

  def product
    Product.fetch_product self.language, self.prod_key
  end

  def self.fetch_newest language, prod_key, verison
    Newest.where(:language => language, :prod_key => prod_key, :version => version).shift
  end

  def self.get_newest( count )
    Newest.all().desc( :created_at ).limit( count )
  end

  def self.since_to(dt_since, dt_to)
    self.where(:created_at.gte => dt_since, :created_at.lt => dt_to).desc(:created_at)
  end

  def self.balanced_newest(count)
    newest = []
    Product.supported_languages.each do |lang|
      newest.concat Newest.where(language: lang).desc(:created_at).limit(count)
    end
    newest.shuffle.first(count)
  end

  def self.balanced_novel(count)
    newest = []
    Product.supported_languages.each do |lang|
      newest.concat Newest.where(language: lang, novel: true).desc(:created_at).limit(count)
    end
    newest.shuffle.first(count)
  end

  def language_esc
    return 'nodejs' if language.eql?(Product::A_LANGUAGE_NODEJS)
    language.downcase
  end

end

