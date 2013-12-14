class Versioncomment

  require 'will_paginate/array'

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id    , type: String

  # Belongs to the product with this attributes
  field :language   , type: String
  field :product_key, type: String
  field :version    , type: String
  field :prod_name  , type: String

  field :comment    , type: String
  field :update_type, type: String

  embeds_many :versioncommentreplys

  validates_presence_of :user_id,     :message => 'User is mandatory!'
  validates_presence_of :product_key, :message => 'Product is mandatory!'
  validates_presence_of :version,     :message => 'Version is mandatory!'
  validates_presence_of :comment,     :message => 'Comment is mandatory!'

  scope :by_user, ->(user){ where(user_id: user.id) }

  def self.find_by_id( id )
    Versioncomment.find( id )
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def self.find_by_user_id(user_id)
    Versioncomment.where(user_id: user_id).desc(:created_at)
  end

  def self.get_prod_keys_for_user(user_id)
    Versioncomment.where(user_id: user_id).distinct(:product_key)
  end

  def self.count_by_user_id( user_id )
    Versioncomment.where(user_id: user_id).count()
  end

  # TODO double check this
  def self.find_by_prod_keys( prod_keys )
    Versioncomment.where(:product_key.in => prod_keys).desc(:created_at)
  end

  def self.find_by_prod_key_and_version(language, prod_key, version)
    Versioncomment.where(language: language, product_key: prod_key, version: version).asc(:created_at)
  end

  def user
    User.find( self.user_id )
  end

  def prod_key_url
    Product.encode_product_key( self.product_key )
  end

  def version_url
    Product.encode_product_key( self.version )
  end

  def name_and_version
    "#{self.prod_name} (#{self.version})"
  end

  def product
    product = nil
    if self.language
      product = Product.fetch_product( self.language, self.product_key)
    end
    return nil if product.nil?
    product.version = self.version
    product
  end

end
