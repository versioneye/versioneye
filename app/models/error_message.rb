class ErrorMessage

  include Mongoid::Document
  include Mongoid::Timestamps

  field :subject, type: String
  field :errormessage, type: String
  field :source, type: String

  belongs_to :crawle
  
end
