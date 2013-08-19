class License

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name         , type: String
  field :identifier   , type: String
  field :url          , type: String
  field :comments     , type: String
  field :distributions, type: String
  field :osi_approved , type: String

end
