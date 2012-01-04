class Crawle
  include Mongoid::Document
  include Mongoid::Timestamps
  field :crawler_name, type: String
  field :crawler_version, type: String
  field :repository_src, type: String
  embeds_many :errors
  
  def crawler_name_and_version
    "#{crawler_name} - #{crawler_version}"
  end
  
  def to_param
    _id.to_s
  end
  
end