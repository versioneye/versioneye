class Error

  include Mongoid::Document
  include Mongoid::Timestamps

  field :subject, type: String
  field :errormessage, type: String

  embedded_in :crawle
  
end