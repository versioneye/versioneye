class SubmittedUrl

  require 'will_paginate/array'

  include Mongoid::Document
  include Mongoid::Timestamps

  field :url, type: String
  field :message, type: String
  field :user_id, type: String
  field :user_email, type: String
  field :search_term, type: String

  belongs_to :product_resource

  validates :url, presence: true
  validates :message, presence: true
  validates :user_email, format: {with: /^([^@\s]+)@((?:[-a-z0-9]+.)+[a-z]{2,})$/i, 
                                  :allow_blank => true}
end
