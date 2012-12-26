class ProductResource
  include Mongoid::Document
  field :url, type: String
  field :resource_type, type: String
  field :crawler_name, type: String

  has_one :submitted_url, autosave: true

  validates_presence_of :url, :resource_type
end
