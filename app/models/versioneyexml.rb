class Versioneyexml

  include Mongoid::Document
  include Mongoid::Timestamps

  field :prod_key, type: String
  field :user_id , type: String
  field :url     , type: String

end
