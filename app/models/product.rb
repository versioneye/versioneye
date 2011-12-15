class Product < ActiveRecord::Base

  require 'will_paginate/array'

  has_many :versions, :dependent => :destroy


  def self.find_by_name(searched_name)
    if searched_name.nil? || searched_name.strip == ""
      return nil
    end
    name1 = searched_name+"%"
    result1 = Product.where("name ilike ?", name1).order("name asc")    
    
    ids = Array.new
    result1.each do |product|
      ids.push product.id
    end
  
    name2 = "%" + searched_name + "%"
    result2 = Product.where("name ilike ? AND id not in (?)", name2, ids).order("name asc")
    result = result1 + result2
    result
  end
  
  def self.find_by_key(searched_key)
    if searched_key.nil? || searched_key.strip == ""
      return nil
    end
    products = Product.where("key ilike ?", searched_key)
    return products[0] unless products.nil?
    return nil
  end
  
  def to_param
    url_key = String.new(key)
    url_key.gsub!("/","--")
    url_key.gsub!(".","~")
    "#{url_key}"
  end
  
  def name_and_version    
    nameversion = "#{name} - (#{version})"
  end
  
  def group_id_with_dotts
    group = String.new(group_id)
    group.gsub!("/", ".")
    group
  end
  
  def self.send_notifications
    Notification.find_each do |notification|
      user = fetch_user notification
      version = notification.version
      product = version.product
      ProductMailer.new_version_email(user, version, product).deliver
      notification.sent_email = true
      notification.save
    end
  end
  
  def self.send_notifications_test
      user = User.new
      user.fullname = "Robert Reiz"
      user.email = "robert.reiz.81@gmail.com"
      version = Version.new
      version.version = "1.0"
      version.link = "http://superlink.de"
      product = Product.new
      product.name = "Spring-Framework"
      ProductMailer.new_version_email(user, version, product).deliver      
  end
  
  private 
  
    def self.fetch_user notification
      user = notification.user
      if user.nil? 
        user = User.new
        unsigenduser = notification.unsigneduser
        user.email = unsigenduser.email
        user.fullname = unsigenduser.email
      end
      user
    end

end