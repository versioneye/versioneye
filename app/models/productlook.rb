class Productlook

  require 'will_paginate/array'

  include Mongoid::Document
  include Mongoid::Timestamps

  field :prod_key, type: String
  field :image, type: String
  field :logo, type: String
  field :backgroundimage, type: String
  field :backgroundcolor, type: String

  def self.find_by_key(prod_key)
    Productlook.first(conditions: {prod_key: prod_key})
  end

end