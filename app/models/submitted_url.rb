class SubmittedUrl
  require 'will_paginate/array'
  include Mongoid::Document
  include Mongoid::Timestamps

  field :url, type: String
  field :message, type: String
  field :user_id, type: String

  attr_accessible :url, :message, :user_id
end
