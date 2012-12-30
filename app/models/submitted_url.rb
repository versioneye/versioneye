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
  field :integrated, type: Boolean, default: false

  belongs_to :product_resource

  validates :url, presence: true
  validates :message, presence: true
  validates :user_email, format: {with: /^([^@\s]+)@((?:[-a-z0-9]+.)+[a-z]{2,})$/i, 
                                  :allow_blank => true}

  scope :as_unchecked, where(declined: nil)
  scope :as_checked, where(:declined.in => [false, true])
  scope :as_accepted, where(declined: false)
  scope :as_declined, where(declined: true)

  def self.find_by_id(id)
    return nil if id.nil?
    id = id.to_s
    return SubmittedUrl.find(id.to_s) if SubmittedUrl.where(_id: id.to_s).exists? 
  end

  def user
    return nil unless user_id 
    User.find_by_id user_id
  end

  def self.check_integration_status
    raise "Implement Me Exception! ... Now!"
  end

  def fetch_user_email
    return user_email if user_email

    user = self.user
    return user.email if user
      
    return nil
  end

  def url_guessed
    if !url.match(/https:\/\/github.com\//).nil?
      new_url = url.gsub("https://github.com/", "https://api.github.com/repos/")
      if !new_url.match("\/$").nil?
        return new_url[0..-2]
      end
      return new_url
    end
    url
  end

  def name_guessed
    if !url.match(/https:\/\/github.com\//).nil?
      name = url.gsub("https://github.com/", "")
      if !name.match("\/$").nil?
        return name[0..-2]
      end
      return name
    end
    url
  end

  def type_guessed
    return "GitHub" if !url.match(/github.com/).nil?
    ""
  end

end