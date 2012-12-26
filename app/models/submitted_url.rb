class SubmittedUrl

  require 'will_paginate/array'

  include Mongoid::Document
  include Mongoid::Timestamps

  field :url, type: String
  field :message, type: String
  field :user_id, type: String
  field :user_email, type: String
  field :search_term, type: String
  field :declined, type: Boolean
  field :declined_message, type: String

  belongs_to :product_resource

  validates :url, presence: true
  validates :message, presence: true
  validates :user_email, format: {with: /^([^@\s]+)@((?:[-a-z0-9]+.)+[a-z]{2,})$/i, 
                                  :allow_blank => true}

  def self.find_by_id(id)
    return nil if id.nil?
    id = id.to_s
    return SubmittedUrl.find(id.to_s) if SubmittedUrl.where(_id: id.to_s).exists? 
  end

  def user
    return nil unless user_id 
    User.find_by_id user_id
  end

  def fetch_user_email
    return user_email if user_email

    user = self.user
    return user.email if user
      
    return nil
  end

end