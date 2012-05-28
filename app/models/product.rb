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

  field :like_overall, type: Integer, default: 0
  field :like_docu, type: Integer, default: 0
  field :like_support, type: Integer, default: 0
  
  field :icon, type: String
  field :twitter_name, type: String 
  field :twitter_hash, type: String

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
  
  def self.find_by_name(searched_name, languages=nil, limit=300)
    return Array.new if searched_name.nil? || searched_name.strip == "" 
    result1 = find_by_name_start_with(searched_name, languages, limit)
    if (result1.nil? || result1.empty?)
      return find_by_name_simple(searched_name, languages, limit)
    elsif 
      prod_keys = result1.map{|w| "#{w.prod_key}"}
      result2 = find_by_name_exclusion(searched_name, languages, prod_keys, limit)
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

  def dependencies(scope)
    scope = main_scope if scope == nil 
    Dependency.find_by_key_version_scope(prod_key, version, scope)
  end

  def dependency_circle(scope)
    scope = main_scope if scope == nil 
    hash = Hash.new
    dependencies = Dependency.find_by_key_version_scope(prod_key, version, scope)
    dependencies.each do |dep|      
      element = CircleElement.new
      element.id = dep.dep_prod_key
      element.text = "#{dep.name} (#{dep.version_for_label})"
      hash[dep.dep_prod_key] = element
    end
    return fetch_deps(hash)
  end

  def fetch_deps(hash)
    if hash.empty? 
      return hash
    end
    p "hash size: #{hash.count}"
    new_hash = Hash.new
    hash.each do |prod_key, element|
      product = Product.find_by_key(element.id)
      dependencies = product.dependencies("runtime")
      dependencies.each do |dep|
        element.connections << "#{dep.dep_prod_key}"
        if hash[dep.dep_prod_key].nil? && new_hash[dep.dep_prod_key].nil?
          new_element = CircleElement.new
          new_element.id = dep.dep_prod_key
          new_element.text = "#{dep.name} (#{dep.version_for_label})"
          new_element.connections << "#{element.id}"
          new_hash[dep.dep_prod_key] = new_element    
        end
      end
    end
    new_merged = fetch_deps(new_hash)
    merged_hash = hash.merge(new_merged)
    return merged_hash
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
    return "0" if val.nil?
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
  
  def as_json(param = {})
    if !param[:only].nil?
      {:value => self.name}
    else
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
        # :src => self.repositories,
        :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
        :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p")
        # :versions => self.get_natural_sorted_versions.as_json(nil), 
        # :comments => comments.as_json
      }  
    end
  end

  def main_scope
    if self.language.eql?("Ruby")
      return "runtime"
    elsif self.language.eql?("Java")
      return "compile"
    end
  end

  private 

    def self.find_by_name_start_with(searched_name, languages, limit)
      if languages.nil? || languages.empty?
        Product.all(conditions: { name: /^#{searched_name}/i }).desc(:like_overall).asc(:name).limit(limit)
      else
        Product.all(conditions: { name: /^#{searched_name}/i, :language.in => languages }).desc(:like_overall).asc(:name).limit(limit)
      end
    end

    def self.find_by_name_simple(searched_name, languages, limit)
      if languages.nil? || languages.empty?
        Product.all(conditions: { name: /#{searched_name}/i }).desc(:like_overall).asc(:name).limit(limit)
      else
        Product.all(conditions: { name: /#{searched_name}/i, :language.in => languages}).desc(:like_overall).asc(:name).limit(limit)
      end
    end

    def self.find_by_name_exclusion(searched_name, languages, prod_keys, limit)
      if languages.nil? || languages.empty?
        Product.all(conditions: { name: /#{searched_name}/i, :prod_key.nin => prod_keys }).desc(:like_overall).asc(:name).limit(limit)
      else
        Product.all(conditions: { name: /#{searched_name}/i, :prod_key.nin => prod_keys, :language.in => languages}).desc(:like_overall).asc(:name).limit(limit)
      end
    end

end