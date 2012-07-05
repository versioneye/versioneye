class Searchlog

  include Mongoid::Document
  include Mongoid::Timestamps

  field :search, type: String
  field :results, type: Integer
  
end