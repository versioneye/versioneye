class Productlike

  require 'will_paginate/array'

  include Mongoid::Document
  include Mongoid::Timestamps

  field :prod_key, type: String
  field :user_id, type: String
  
  field :overall, type: Integer, default: 0
  field :documentation, type: Integer, default: 0
  field :support, type: Integer, default: 0

  def self.find_by_user_id_and_product(user_id, product_key)
    Productlike.where( user_id: user_id, prod_key: product_key )[0]
  end

  def overall_like_display
    "block" if overall == 0 
    "none" if overall == 1
  end

  def overall_dislike_display
    "block" if overall == 1 
    "none" if overall == 0
  end

  def docu_like_display
    "block" if documentation == 0 
    "none" if documentation == 1
  end

  def docu_dislike_display
    "block" if documentation == 1 
    "none" if documentation == 0
  end

  def support_like_display
    "block" if support == 0 
    "none" if support == 1
  end

  def support_dislike_display
    "block" if support == 1 
    "none" if support == 0
  end

end