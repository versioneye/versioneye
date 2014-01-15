class ProductResource

  include Mongoid::Document

  field :url          , type: String
  field :name         , type: String
  field :resource_type, type: String
  field :crawler_name , type: String
  field :crawled      , type: Boolean, default: false
  field :prod_key     , type: String
  field :prod_type    , type: String
  field :language     , type: String

  has_one :submitted_url, autosave: true

  validates_presence_of :url, :resource_type

  def self.find_by_id( id )
    return nil if id.to_s.strip.empty?
    id = id.to_s
    return ProductResource.find(id) if ProductResource.where(_id: id).exists?
  end

end
