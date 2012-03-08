class Crawle

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes

  field :crawler_name, type: String
  field :crawler_version, type: String
  field :repository_src, type: String
  field :exec_group, type: String
  field :duration, type: DateTime
  
  embeds_many :errors
  
  def crawler_name_and_version
    "#{crawler_name} - #{crawler_version}"
  end
  
  def to_param
    _id.to_s
  end
  
end