class Searchlog

  # TODO safe somewhere else ?

  include Mongoid::Document
  include Mongoid::Timestamps

  field :search, type: String
  field :results, type: Integer
  field :wait, type: Float

end
