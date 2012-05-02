class Product

  require 'will_paginate/array'

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes # Need for type: DateTime 

  field :name, type: String
  field :prod_key, type: String
  field :prod_type, type: String
  field :language, type: String
  
  field :group_id, type: String
  field :artifact_id, type: String
  
  field :authors, type: String
  field :description, type: String
  field :link, type: String
  field :downloads, type: Integer
  field :followers, type: Integer, default: 0
  field :license, type: String 
  field :licenseLink, type: String 
  
  field :version, type: String
  field :version_link, type: String
  field :version_rate, type: Integer
  field :version_rate_docu, type: Integer
  field :version_rate_support, type: Integer
  
  field :rate, type: Integer
  field :rate_docu, type: Integer
  field :rate_support, type: Integer
  field :ratecount, type: Integer
  
  field :icon, type: String

  embeds_many :versions
  embeds_many :repositories
  # versionarchives
  # versionlinks
  # versionchanges
  # versioncomments

  attr_accessor :in_my_products, :version_uid
  
  def delete
    false
  end
  
  def self.find_by_name(searched_name, languages=nil)
    return Array.new if searched_name.nil? || searched_name.strip == "" 
    result1 = find_by_name_start_with(searched_name, languages)
    if (result1.nil? || result1.empty?)
      return find_by_name_simple(searched_name, languages)
    elsif 
      ids = Array.new
      result1.each do |product|
        ids.push product.prod_key
      end 
      result2 = find_by_name_exclusion(searched_name, languages, ids)      
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
  
  def self.find_by_group_and_artifact(group, artifact)
    Product.first(conditions: { group_id: group, artifact_id: artifact } )
  end
  
  def get_natural_sorted_versions
    Naturalsorter::Sorter.sort_version_by_method_desc(versions, "version")
  end
  
  def get_newest_version_by_natural_order
    versions = get_natural_sorted_versions
    versions.first.version
  end

  def get_version_by_uid(uid)
    versions.each do |version|
      return version if version.uid.eql?(uid)
    end
    return nil
  end
  
  def wouldbenewest?(version)
    current = get_newest_version_by_natural_order
    return false if current.eql? version
    newest = Naturalsorter::Sorter.get_newest_version(current, version) 
    return true if newest.eql? version
    return false
  end
  
  def get_version(searched_version)
    versions.each do |version|
      return version if version.version.eql?(searched_version)
    end
    nil
  end 
  
  def versions_empty?
    versions.nil? || versions.size == 0 ? true : false
  end

  def self.random_product
    size = Product.count - 7
    Product.skip(rand( size )).first 
  end
  
  def get_links
    Versionlink.all(conditions: { prod_key: self.prod_key, version_id: nil}).asc(:name)
  end
  
  def get_version_links()
    Versionlink.all(conditions: { prod_key: self.prod_key, version_id: self.version}).asc(:name)
  end
  
  def self.get_hotest( count )
    Product.all().desc(:followers).limit( count )
  end
  
  def update_rate
    rate_sum = 0
    rate_count = 0
    rate_docu_sum = 0
    rate_docu_count = 0
    rate_support_sum = 0
    rate_support_count = 0
    versions.each do |version|
      if !version.rate.nil? && version.rate > 9 
        rate_count += 1
        rate_sum += version.rate
      end
      if !version.rate_docu.nil? && version.rate_docu > 9
        rate_docu_count += 1
        rate_docu_sum += version.rate_docu
      end
      if !version.rate_support.nil? && version.rate_support > 9
        rate_support_count += 1
        rate_support_sum += version.rate_support
      end
    end
    if rate_count > 0
      avg = rate_sum / rate_count 
      self.rate = Versioncomment.get_flatted_average(avg)
    end    
    if rate_docu_count > 0 
      avg = rate_docu_sum / rate_docu_count
      self.rate_docu = Versioncomment.get_flatted_average(avg)
    end
    if rate_support_count > 0 
      avg = rate_support_sum / rate_support_count
      self.rate_support = Versioncomment.get_flatted_average(avg)
    end
  end
  
  def update_version_rates    
    versions.each do |version|
      version.update_rate
      version.update_rate_docu
      version.update_rate_support
      version.save
    end
  end
  
  def update_version_data
    versions = get_natural_sorted_versions
    if !versions.nil?
      versions.each do |version|
        if version.mistake != true && !versions.eql?(self.versions)
          self.version = version.version
          self.version_link = version.link
          self.save
          break
        end
      end
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
  
  def self.update_followers
    ids = Follower.all.distinct( :product_id )
    ids.each do |id|
      count = Follower.all(conditions: {product_id: id}).count
      product = Product.find(id)
      product.followers = count
      product.save
      p "#{id} - #{product.name} - #{count}"
    end
  end

  def self.get_unique_languages_for_product_ids(product_ids)
    Product.where(:_id.in => product_ids).distinct(:language)
  end

  def self.get_unique_languages
    Product.all().distinct(:language)
  end

  def update_in_my_products(array_of_product_ids)
    self.in_my_products = array_of_product_ids.include?(_id.to_s)
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
    "#{name} (#{version})"
  end
  
  def name_version(limit)    
    nameversion = "#{name} (#{version})"
    if nameversion.length > limit
      return "#{nameversion[0, limit]}.." 
    else
      return nameversion
    end
  end
    
  def as_json param
    comments = Versioncomment.find_by_prod_key_and_version(self.prod_key, self.version)
    {
      :following => param[:following],
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

  private 

    def self.find_by_name_start_with(searched_name, languages)
      if languages.nil? || languages.empty?
        Product.all(conditions: { name: /^#{searched_name}/i }).desc(:rate).asc(:name).limit(300)
      else
        Product.all(conditions: { name: /^#{searched_name}/i, :language.in => languages }).desc(:rate).asc(:name).limit(300)
      end
    end

    def self.find_by_name_simple(searched_name, languages)
      if languages.nil? || languages.empty?
        Product.all(conditions: { name: /#{searched_name}/i }).desc(:rate).asc(:name).limit(300)
      else
        Product.all(conditions: { name: /#{searched_name}/i, :language.in => languages}).desc(:rate).asc(:name).limit(300)
      end
    end

    def self.find_by_name_exclusion(searched_name, languages, ids)
      if languages.nil? || languages.empty?
        Product.all(conditions: { name: /#{searched_name}/i, prod_key: "{$nin: #{ids} }" }).desc(:rate).asc(:name).limit(300)
      else
        Product.all(conditions: { name: /#{searched_name}/i, prod_key: "{$nin: #{ids} }", :language.in => languages}).desc(:rate).asc(:name).limit(300)
      end
    end

end