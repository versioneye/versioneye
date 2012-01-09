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
  field :rate, type: Integer
  embeds_many :versions
  embeds_many :repositories

  require 'will_paginate/array'

  def self.find_by_name(searched_name)
    if searched_name.nil? || searched_name.strip == ""
      return nil
    end
    result1 = Product.all(conditions: { name: /^#{searched_name}/i }).asc(:name)
    if (result1.nil? || result1.empty?)
      result1 = Product.all(conditions: { name: /#{searched_name}/i }).asc(:name)    
      result1
    elsif 
      ids = Array.new
      result1.each do |product|
        ids.push product.prod_key
      end 
      result2 = Product.all(conditions: { name: /#{searched_name}/i, prod_key: "{$nin: #{ids} }" }).asc(:name)
      result = result1 + result2
      result
    end
  end
  
  def self.find_by_key(searched_key)
    if searched_key.nil? || searched_key.strip == ""
      return nil
    end
    result = Product.where(prod_key: searched_key )
    if (result.nil? || result.empty?)
      return nil
    end
    return result[0]    
  end
  
  def get_natural_sorted_versions
    Naturalsorter::Sorter.sort_by_method(versions, "version", true)
  end
  
  def get_version(searched_version)
    versions.each do |version|
      if version.version.eql?(searched_version)
        return version
      end
    end
    return nil
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
  
  def self.update_versions
    count = Product.count()
    pack = 100
    max = count / pack 
    (0..max).each do |i|
      skip = i * pack
      products = Product.all().skip(skip).limit(pack)
      products.each do |product|
        product.update_version
      end
    end
  end
  
  def update_version
    versions = get_natural_sorted_versions
    version = versions[versions.count() - 1]
    self.version = version.version
    self.version_link = version.link
    self.save
    p "update product #{prod_key} with version: #{version.link}"
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
    Product.to_url_param prod_key    
  end
  
  def version_to_url_param
    Product.to_url_param version    
  end
  
  def self.to_url_param val
    url_param = String.new(val)
    url_param.gsub!("/","--")
    url_param.gsub!(".","~")
    "#{url_param}"    
  end
  
  def name_and_version    
    nameversion = "#{name} (#{version})"
  end
  
  def group_id_with_dotts
    group = String.new(group_id)
    group.gsub!("/", ".")
    group
  end
  
  def as_json param
    comments = Versioncomment.find_by_prod_key_and_version(self.prod_key, self.version)
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
      :versions => self.get_natural_sorted_versions.as_json, 
      :comments => comments.as_json
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