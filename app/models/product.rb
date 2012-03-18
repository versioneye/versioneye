class Product

  require 'will_paginate/array'

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes # Need for type: DateTime 

  field :name, type: String
  field :prod_key, type: String
  field :prod_type, type: String
  
  field :group_id, type: String
  field :artifact_id, type: String
  
  field :authors, type: String
  field :description, type: String
  field :link, type: String
  field :downloads, type: Integer  
  field :license, type: String 
  field :licenseLink, type: String 
  
  field :version, type: String
  field :version_link, type: String
  field :version_rate, type: Integer  
  
  field :rate, type: Integer
  field :ratecount, type: Integer
  
  field :icon, type: String

  embeds_many :versions
  embeds_many :repositories
  # versionarchives
  # versionlinks
  # versionchanges
  # versioncomments

  attr_accessor :in_my_products, :version_uid, :notification

  
  def delete
    false
  end
  
  def self.find_by_name(searched_name)
    return Array.new if searched_name.nil? || searched_name.strip == ""  
    result1 = Product.all(conditions: { name: /^#{searched_name}/i }).desc(:rate).asc(:name).limit(300)
    if (result1.nil? || result1.empty?)
      Product.all(conditions: { name: /#{searched_name}/i }).desc(:rate).asc(:name).limit(300)
    elsif 
      ids = Array.new
      result1.each do |product|
        ids.push product.prod_key
      end 
      result2 = Product.all(conditions: { name: /#{searched_name}/i, prod_key: "{$nin: #{ids} }" }).desc(:rate).asc(:name).limit(300)
      result = result1 + result2
      result
    end
  rescue
    Array.new
  end
  
  def self.find_by_key(searched_key)
    return nil if searched_key.nil? || searched_key.strip == ""
    result = Product.where(prod_key: searched_key )
    return nil if (result.nil? || result.empty?)
    return result[0]    
  end
  
  def self.find_by_id(id)
    return nil if id.nil? || id.strip == ""
    result = Product.find(id)
    result
  rescue
    nil
  end
  
  def get_natural_sorted_versions
    Naturalsorter::Sorter.sort_by_method(versions, "version", true)
  end
  
  def get_newest_version_by_natural_order
    versions = get_natural_sorted_versions
    versions.last.version
  end
  
  def get_version(searched_version)
    versions.each do |version|
      return version if version.version.eql?(searched_version)
    end
    return nil
  end 
  
  def versions_empty?
    versions.nil? || versions.size == 0 ? true : false
  end
  
  def get_version_by_uid(uid)
    versions.each do |version|
      return version if version.uid.eql?(uid)
    end
    return nil
  end
  
  def get_links
    Versionlink.all(conditions: { prod_key: self.prod_key}).asc(:name)
  end
  
  def update_rate
    rate_sum = 0
    rate_count = 0
    ratecount_sum = 0
    versions.each do |version|
      if !version.rate.nil? && version.rate > 9 
        rate_count += 1
        rate_sum += version.rate
        ratecount_sum += version.get_ratecount
      end
    end
    if rate_count > 0
      avg = rate_sum / rate_count 
      self.rate = Versioncomment.get_flatted_average(avg)
      self.ratecount = ratecount_sum    
    end    
  end
  
  def update_version_rates    
    versions.each do |version|
      version.update_rate
      version.save
    end
  end
  
  def update_version_data
    versions = get_natural_sorted_versions
    if !versions.nil?
      version = versions[versions.count() - 1]
      self.version = version.version
      self.version_link = version.link
      self.update_rate
      self.save      
    end
  end
  
  def self.update_version_data_global
    count = Product.count()
    pack = 100
    max = count / pack     
    (0..max).each do |i|
      skip = i * pack
      products = Product.all().skip(skip).limit(pack)
      products.each do |product|
        product.update_version_rates
        product.update_version_data
      end
    end
  end
    
  def update_in_my_products(array_of_product_ids)
    self.in_my_products = array_of_product_ids.include?(_id.to_s)
  end
  
  def display_follow
    if self.in_my_products
      "none"
    else
      "block"
    end
  end
  
  def display_unfollow
    if self.in_my_products
      "block"
    else
      "none"
    end
  end
  
  def to_param
    Product.to_url_param prod_key    
  end
  
  def version_to_url_param
    Product.to_url_param version    
  end
  
  def self.to_url_param val
    if val.nil?
      return "0"
    end
    url_param = String.new(val)
    url_param.gsub!("/","--")
    url_param.gsub!(".","~")
    "#{url_param}"    
  end
  
  def name_and_version    
    nameversion = "#{name} (#{version})"
  end
  
  def get_type
    if prod_type.nil? || prod_type.empty? 
      "Maven2"
    else
      prod_type
    end
  end
  
  def get_decimal_id
    _id.to_s.to_i(16).to_s(10)
  end
  
  def get_decimal_version_uid
    version = get_version(self.version)
    if !version.nil? && !version.uid.nil?
      version.uid.to_s.to_i(16).to_s(10)
    else  
      "0"
    end
  end
  
  def self.decimal_to_hex( decimal )
    return nil if decimal.nil? 
    decimal.to_i(10).to_s(16)
  end
    
  def as_json param
    comments = Versioncomment.find_by_prod_key_and_version(self.prod_key, self.version)
    {
      :following => param[:following],
      :notification => self.notification,
      :id => self.get_decimal_id,
      :version_uid => self.get_decimal_version_uid,
      :name => self.name,
      :key => self.prod_key,
      :group_id => self.group_id,
      :artifact_id => self.artifact_id,      
      :link => self.link,
      :version => self.version,
      :version_link => self.version_link,
      :src => self.repositories,
      :prod_type => self.get_type,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
      :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p"),
      :versions => self.get_natural_sorted_versions.as_json, 
      :comments => comments.as_json
    }
  end

end