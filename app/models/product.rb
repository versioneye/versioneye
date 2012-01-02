class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :prod_key, type: String
  field :group_id, type: String
  field :artifact_id, type: String
  field :link, type: String
  field :version, type: String
  field :version_link, type: String
  embeds_many :versions
  embeds_many :repositories

  require 'will_paginate/array'

  def self.find_by_name(searched_name)
    if searched_name.nil? || searched_name.strip == ""
      return nil
    end
    result1 = Product.all(conditions: { name: /^#{searched_name}/i })
    if (result1.nil? || result1.empty?)
      result1 = Product.all(conditions: { name: /#{searched_name}/i })    
      result1
    elsif 
      ids = Array.new
      result1.each do |product|
        ids.push product.prod_key
      end 
      result2 = Product.all(conditions: { name: /#{searched_name}/i, prod_key: "{$nin: #{ids} }" })
      result = result1 + result2
      result
    end
  end
  
  def self.find_by_key(searched_key)
    if searched_key.nil? || searched_key.strip == ""
      return nil
    end
    Product.first(conditions: { prod_key: /^#{searched_key}/i })    
  end
  
  def self.send_notifications_job
    one_min = 60
    one_hour = one_min * 60
    while true do
      send_notifications
      p "start to make a nap"
      sleep one_hour
      p "wake up"
    end
  end
  
  def self.send_notifications
    Notification.find_each(:conditions => "sent_email is false") do |notification|
      user = fetch_user notification
      version = notification.version
      product = version.product
      ProductMailer.new_version_email(user, version, product).deliver
      notification.sent_email = true
      notification.save
    end
  end
  
  def to_param
    url_key = String.new(prod_key)
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
  
  def as_json param
    {
      :following => param[:following],
      :name => self.name,
      :key => self.prod_key,
      :group_id => self.group_id,
      :artifact_id => self.artifact_id,      
      :link => self.link,
      :version => self.version,
      :version_link => self.version_link,
      :src => self.repositories,
      :prod_type => self.repositories[0].repotype,
      :created_at => self.created_at,
      :updated_at => self.updated_at,
      :versions => self.versions.as_json      
    }
  end
  
  private 
  
    def self.fetch_user notification
      user = notification.user
      if user.nil? 
        user = User.new
        unsigenduser = notification.unsigneduser
        user.email = unsigenduser.email
        user.fullname = user.email
      end
      user
    end

end