class ApiCall
  include Mongoid::Document
  include Mongoid::Timestamps

  field :api_key, type: String
  field :api_call, type: Integer
  field :ip,      type: String

  validates :api_key, presence: true
  validates :api_call, presence: true

end
