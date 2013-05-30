class ErrorMessage

  require 'will_paginate/array'

  include Mongoid::Document
  include Mongoid::Timestamps

  field :subject     , type: String
  field :errormessage, type: String
  field :source      , type: String

  belongs_to :crawle

  def self.fetch_page( page_number  )
    page_number = 1 if page_number.nil?
    query = Mongoid::Criteria.new(ErrorMessage)
    query.paginate( :page => page_number, :per_page => 30 )
  end

end
