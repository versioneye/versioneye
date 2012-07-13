class Product

  require 'will_paginate/array'

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes # Need for type: DateTime 

  field :name, type: String
  field :name_downcase, type: String
  field :prod_key, type: String
  field :prod_type, type: String
  field :language, type: String
  
  field :group_id, type: String
  field :artifact_id, type: String
  
  field :authors, type: String
  field :description, type: String
  field :description_manual, type: String
  field :link, type: String
  field :downloads, type: Integer
  field :followers, type: Integer, default: 0
  
  field :license, type: String 
  field :licenseLink, type: String 
  field :license_manual, type: String 
  field :licenseLink_manual, type: String
  
  field :version, type: String
  field :version_link, type: String

  field :like_overall, type: Integer, default: 0
  field :like_docu, type: Integer, default: 0
  field :like_support, type: Integer, default: 0
  
  field :icon, type: String
  field :twitter_name, type: String 

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

  def self.find_by(searched_name, description, group_id, languages=nil, limit=300)
    query = Mongoid::Criteria.new(Product)
    if searched_name && !searched_name.empty?
      query = Product.find_by_name(searched_name)
      if query.nil? || query.count == 0
        query = Product.find_by_description(searched_name)
      else 
        query = add_description_to_query(query, description)  
      end  
    elsif description && !description.empty?
      query = Product.find_by_description(description)
    else
      return Mongoid::Criteria.new(Product, {_id: -1})
    end
    query = add_to_query(query, group_id, languages)
    query = query.desc(:followers).asc(:name).limit(limit)
    return query
  rescue => e
    p "#{e}" 
    Mongoid::Criteria.new(Product, {_id: -1})
  end

  def self.find_by_name(searched_name)
    if (searched_name.nil? || searched_name.strip == "")
      return nil
    end
    query = Product.where(name_downcase: /^#{searched_name}/)
    if (query.nil? || query.empty?)
      return query = Product.where(name_downcase: /#{searched_name}/)
    else
      prod_keys = query.map{|w| "#{w.prod_key}"}
      result2 = Product.all(conditions: { name_downcase: /#{searched_name}/, :prod_key.nin => prod_keys})
      result = query + result2
      prod_keys = result.map{|w| "#{w.prod_key}"}
      end_result = Product.all(conditions: { :prod_key.in => prod_keys})
      end_result
    end
  rescue => e
    p "rescue #{e}"
    Mongoid::Criteria.new(Product, {_id: -1})
  end

  def self.find_by_description(description)
    if (description.nil? || description.strip == "")
      return Mongoid::Criteria.new(Product, {_id: -1})
    end
    query = Product.all(conditions: {"$or" => [ {"description" => /#{description}/i}, {"description_manual" => /#{description}/i} ] })
    query
  rescue => e
    p "rescue #{e}"
    Mongoid::Criteria.new(Product, {_id: -1})
  end
  
  def self.find_by_key(searched_key)
    return nil if searched_key.nil? || searched_key.strip == ""
    result = Product.where(prod_key: searched_key)
    return nil if (result.nil? || result.empty?)
    return result[0]    
  end

  # This is slow !! Searches by regex are always slower than exact searches!
  def self.find_by_key_case_insensitiv(searched_key)
    return nil if searched_key.nil? || searched_key.strip == ""
    result = Product.all(conditions: {prod_key: /^#{searched_key}$/i})
    return nil if (result.nil? || result.empty?)
    return result[0]    
  end

  def self.find_by_keys(product_keys)
    Product.where(:prod_key.in => product_keys)
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
    if scope == nil 
      scope = main_scope
    end
    
    hash = Hash.new
    dependencies = Dependency.find_by_key_version_scope(prod_key, version, scope)
    dependencies.each do |dep|      
      element = CircleElement.new
      element.id = dep.dep_prod_key
      attach_label_to_element(element, dep)
      element.version = dep.version_abs
      hash[dep.dep_prod_key] = element
    end
    return fetch_deps(1, hash, Hash.new)
  end

  def fetch_deps(deep, hash, parent_hash)
    return hash if hash.empty? 
    # deep_space = ""
    # deep.times{
    #   deep_space = "#{deep_space}  "
    # }
    # deep = deep + 1
    # p "#{deep_space} hash size: #{hash.count} parent_hash size: #{parent_hash.count}"
    new_hash = Hash.new
    hash.each do |prod_key, element|
      product = Product.find_by_key(element.id)
      if product.nil?
        p "#{element.id} #{element.version} not found!"
        next
      end
      if (element.version && !element.version.eql?("") && !element.version.eql?("0"))
        product.version = element.version
      end
      dependencies = product.dependencies(nil)
      # p "#{deep_space} #{dependencies.count} deps for #{product.name} #{product.version}"
      dependencies.each do |dep|
        key = dep.dep_prod_key
        ele = get_element_from_hash(new_hash, hash, parent_hash, key)
        if ele.nil?
          # p "#{deep_space}  create new element #{dep.name}"
          new_element = CircleElement.new
          new_element.id = dep.dep_prod_key          
          attach_label_to_element(new_element, dep)
          new_element.connections << "#{element.id}"
          new_element.version = dep.version_abs
          new_hash[dep.dep_prod_key] = new_element
        else 
          # p "#{deep_space}  element #{dep.name} already fetched"
          ele.connections << "#{element.id}"
        end
        element.connections << "#{key}"
      end
    end
    # p "#{deep_space} new hash element #{new_hash.count}"
    parent_merged = hash.merge(parent_hash)
    rec_hash = fetch_deps(deep, new_hash, parent_merged)
    merged_hash = parent_merged.merge(rec_hash)
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
    return if self.versions.nil? || self.versions.length < 2
    
    versions = get_natural_sorted_versions
    version = versions.first
    
    if version.mistake == true 
      p " -- mistake #{self.name} with version #{version.version}"
      return 
    end
    
    return if version.version.eql?(self.version)
      
    self.version = version.version
    self.version_link = version.link
    self.save
    p " udpate #{self.name} with version #{self.version}"
  rescue
    p " -- ERROR -- something went wrong --- "
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

  def self.update_name_downcase_global
    products = Product.where(name_downcase: nil)
    products.each do |product|
      product.name_downcase = String.new(product.name.downcase)
      product.save
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
    "#{name} : #{version}"
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
    elsif self.language.eql?("Node.JS")
      return "compile"
    end
  end

  private 

    def self.add_description_to_query(query, description)
      if (description && !description.empty?)
        query = query.where("$or" => [ {"description" => /#{description}/i}, {"description_manual" => /#{description}/i} ] )
      end
      query
    end

    def self.add_to_query(query, group_id, languages)
      if (group_id && !group_id.empty?)
        query = query.where(group_id: /^#{group_id}/i)
      end
      if languages && !languages.empty?
        query = query.in(language: languages)
      end
      query
    end

    def get_element_from_hash(new_hash, hash, parent_hash, key)
      element = new_hash[key]
      return element if !element.nil?
      element = hash[key]
      return element if !element.nil?
      element = parent_hash[key]
      return element
    end

    def attach_label_to_element(element, dep)
      element.text = dep.name
      if dep.version_for_label && !dep.version_for_label.empty? 
        element.text += ":#{dep.version_for_label}"
      end
    end

end