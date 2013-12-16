class SubmittedUrl

  require 'will_paginate/array'

  include Mongoid::Document
  include Mongoid::Timestamps

  field :url             , type: String
  field :message         , type: String
  field :user_id         , type: String
  field :user_email      , type: String
  field :search_term     , type: String
  field :declined        , type: Boolean
  field :declined_message, type: String
  field :integrated      , type: Boolean, default: false

  belongs_to :product_resource

  validates :url       , presence: true
  validates :message   , presence: true
  validates :user_email, format: {with: /^([^@\s]+)@((?:[-a-z0-9]+.)+[a-z]{2,})$/i, :allow_blank => true}

  scope :as_unchecked     , where(declined: nil)
  scope :as_checked       , where(:declined.in => [false, true])
  scope :as_accepted      , where(declined: false)
  scope :as_declined      , where(declined: true)
  scope :as_not_integrated, where(integrated: false)

  def self.find_by_id(id)
    return nil if id.nil?
    id = id.to_s
    return self.find(id.to_s) if self.where(_id: id.to_s).exists?
  end

  def user
    User.find_by_id user_id
  end

  def self.update_integration_statuses()
    SubmittedUrl.as_not_integrated.each do |submitted_url|
      submitted_url.update_integration_status
    end
  end

  def update_integration_status
    resource = self.product_resource
    @product = nil
    if resource && !resource.prod_key.nil?
      @product = Product.fetch_product( resource.language, resource.prod_key )
    end

    self.integrated = true unless @product.nil?

    if self.save and not @product.nil?
      @submitted_url = self
      SubmittedUrlMailer.integrated_url_email(@submitted_url, @product).deliver
      return true
    else
      $stderr.puts "Failed to update integration status for submittedUrl.#{self._id}"
      $stderr.puts self.errors.full_messages.to_sentence
    end
    false
  end

  def url_guessed
    unless url.match(/https:\/\/github.com\//).nil?
      new_url = url.gsub('https://github.com/', 'https://api.github.com/repos/')
      unless new_url.match("\/$").nil?
        return new_url[0..-2]
      end
      return new_url
    end
    url
  end

  def name_guessed
    unless url.match(/https:\/\/github.com\//).nil?
      name = url.gsub('https://github.com/', '')
      unless name.match("\/$").nil?
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
