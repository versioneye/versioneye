class Product

  require 'will_paginate/array'
  require 'yajl/json_gem'
  require 'tire'

  include Mongoid::Document
  include Mongoid::Timestamps

  include Tire::Model::Search
  include Tire::Model::Callbacks

  field :name, type: String
  field :name_downcase, type: String
  field :prod_key, type: String
  field :prod_type, type: String
  field :language, type: String
  
  field :group_id, type: String
  field :artifact_id, type: String
  field :parent_id, type: String
  
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

  field :reindex, type: Boolean, default: true

  embeds_many :versions
  embeds_many :repositories
  # versionarchives
  # versionlinks
  # versionchanges
  # versioncomments

  attr_accessor :in_my_products, :version_uid, :last_crawle_date

  def delete
    false
  end

  def self.search(q, description = nil, group_id = nil, languages = nil)
    results_json = self.elastic_search(q, group_id, languages)
    results = Array.new
    results_json.each do |obj|
      product = Product.new
      product.name = obj[:name]
      product.prod_key = obj[:prod_key]
      product.group_id = obj[:group_id]
      product.language = obj[:language]
      product.prod_type = obj[:prod_type]
      product.version = obj[:version]
      product.followers = obj[:followers]
      results.push product
      p " - #{product.group_id} - #{product.language} - #{product.version}"
    end
    results
  rescue => e 
    p "#{e}"
    e.backtrace.each do |message|
      p " - #{message}"
    end
    self.find_all(q, description, group_id, languages=nil)
  end

  def self.find_by(searched_name, description, group_id, languages=nil, limit=300)
    result1 = Product.find_all(searched_name, description, group_id, languages, limit, nil)

    if searched_name.nil? || searched_name.empty? 
      return result1 
    end

    prod_keys = Array.new
    if result1 && !result1.empty?
      prod_keys = result1.map{|w| "#{w.prod_key}"}
    end
    result2 = Product.find_all(searched_name, description, group_id, languages, limit, prod_keys)  
    result = result1 + result2
    return result
  end

  def self.find_all(searched_name, description, group_id, languages=nil, limit=300, exclude_keys)
    query = Mongoid::Criteria.new(Product)
    if searched_name && !searched_name.empty?
      if exclude_keys 
        query = Product.find_by_name_exclude(searched_name, exclude_keys)
      else 
        query = Product.find_by_name(searched_name)  
      end
    elsif description && !description.empty?
      query = Product.find_by_description(description)
    elsif group_id && !group_id.empty?
      return Product.where(group_id: /^#{group_id}/).desc(:followers).asc(:name).limit(limit)
    else
      return Mongoid::Criteria.new(Product, {_id: -1})
    end
    query = add_to_query(query, group_id, languages)
    query = query.desc(:followers).asc(:name).limit(limit)
    return query
  rescue => e
    p "#{e}" 
    e.backtrace.each do |message|
      p " - #{message}"
    end
    Mongoid::Criteria.new(Product, {_id: -1})
  end

  def self.find_by_name(searched_name)
    if (searched_name.nil? || searched_name.strip == "")
      return nil
    end
    Product.where(name_downcase: /^#{searched_name}/)
  rescue => e
    p "rescue #{e}"
    Mongoid::Criteria.new(Product, {_id: -1})
  end

  def self.find_by_name_exclude(searched_name, prod_keys)
    if (searched_name.nil? || searched_name.strip == "")
      return nil
    end
    Product.all(conditions: { name_downcase: /#{searched_name}/, :prod_key.nin => prod_keys})
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
  rescue => e 
    p "ERROR #{e}"
    e.backtrace.each do |message| 
      p " - #{message}"
    end
    nil
  end
  
  def self.find_by_group_and_artifact(group, artifact)
    Product.where( group_id: group, artifact_id: artifact )[0]
  end

  ######## ELASTIC SEARCH START #####################################
  #include Tire/Elasticsearch helpers

  @@index_name = "products"
  @@search_fields = ["prod_key", "name", "description", "description_manual", "language", "group_id"]
              
  def type
    @@index_name
  end 

  def to_indexed_json
    self.as_json
  end

  def elastic_mapping
    Tire.index @@index_name do
      create :mappings => {
          :article => {
            :properties => {
              :prod_key => {:type => 'string', :index => 'not_analyzed', :include_in_all => false},
              :name => {:type => 'string', :analyzer => 'snowball', :boost => 2.0},
              :description => {:type => 'string', :analyzer => 'snowball'},
              :description_manual => {:type => 'string', :analyzer => 'snowball'},
              :language => {:type => 'string', :index => 'not_analyzed', :analyzer => 'snowball'},
              :prod_type => {:type => 'string', :index => 'not_analyzed', :include_in_all => false},
              :version => {:type => 'string', :index => 'not_analyzed', :include_in_all => false},
              :followers => {:type => 'integer', :index => 'not_analyzed', :include_in_all => false},
              :group_id => {:type => 'string', :analyzer => 'snowball'}
            }
          }
        }
      refresh
    end
  rescue => e
    puts "Cant add object mappings into elasticsearch. #{e}"
  end

  def index_one
    # builds search index for current doc
    elastic_mapping
    index_vals = self.to_hash.select {|key| key.in? @@search_fields}
    r = Tire.index @@index_name do
      store index_vals
      refresh
    end
    # JSON.parse(r.response.body)
  end

  def self.index_newest
    # indexest newest and updated products
    elastic_mapping
    r = Tire.index @@index_name do
      Product.where(reindex: true).each do |doc|
          store doc.to_hash.select {|key| key.in? @@search_fields}
          # turn reindexing flag off         
          doc.update_attribute(:reindex, false) #.save!
      end
      refresh
    end
    # JSON.parse(r.response.body)
  end

  def self.index_all
    # indexes all products on Elasticsearch
    clean_all
    elastic_mapping
    r = Tire.index @@index_name do 
      # add search index for every doc
      Product.all.each do |doc|  
        store doc.to_hash.select {|key| key.in? @@search_fields}
        p "index #{doc.name}"
      end
      refresh
    end
    # JSON.parse(r.response.body)
  end

  def self.clean_all
    # remove all indexes on products
    r = Tire.index @@index_name do
      delete
    end
    # JSON.parse(r.response.body)
  end

  def self.elastic_search(q, group_id = nil, langs = nil)
    q = '*' if q.nil? or q.strip.size < 2
    langs = '' if langs.nil? || langs.match(/^,$/)
    group_id = '' if group_id.nil?
    langs.downcase! 
    response = []
    s = Tire.search(@@index_name) do |search|
      search.size 100        #  Limit record
      search.from 0          #  start offeset
      search.query do |query|
        if q != '*' and group_id != ''
          query.boolean do
            must {string q}                                  
            must {string 'group_id:' + group_id + "*"}                                                    
          end
        elsif q != '*' and group_id == ''
          query.string q
        elsif q == '*' and group_id != '' 
          query.string "group_id:" + group_id + "*" 
        end

        if langs.size > 0 then
          search.filter :terms, :language => langs.split(',')
        end
      end
    end
    s.results.each {|item| response << item.to_hash}
    response
  rescue => e
    puts "Error!! #{e}"
    Array.new
  end

  ########### VERSIONS START ########################

  def get_natural_sorted_versions
    Naturalsorter::Sorter.sort_version_by_method_desc(versions, "version")
  end

  def get_newest_version_by_natural_order
    versions = get_natural_sorted_versions
    versions.first.version
  end

  def self.get_newest_version_by_natural_order(versions)
    if !versions || versions.empty?
      return nil
    end
    ordered_versions = Naturalsorter::Sorter.sort_version_by_method_desc(versions, "version")
    ordered_versions.first
  end

  def get_version(searched_version)
    versions.each do |version|
      return version if version.version.eql?(searched_version)
    end
    nil
  end 

  def get_version_by_uid(uid)
    versions.each do |version|
      return version if version.uid.eql?(uid)
    end
    return nil
  end

  def self.get_approximately_greater_than_starter(value)
    if value.match(/\.0$/)
      new_end = value.length - 2
      return value[0..new_end]
    else 
      return "#{value}."
    end
  end

  def get_tilde_newest(value)
    
    new_st = "#{value}"
    if value.match(/./)
      splits = value.split(".")
      new_end = splits.size - 2
      new_slice = splits[0..new_end]
      new_st = new_slice.join(".")
    end
    starter = "#{new_st}."
    
    versions_group1 = self.get_versions_start_with(starter)
    versions = Array.new
    versions_group1.each do |version| 
      if Naturalsorter::Sorter.bigger_or_equal?(version.version, value)
        versions.push(version)
      end
    end
    Product.get_newest_version_by_natural_order(versions)
  end

  def get_version_range(start, stop)
    # get all versions from range ( >=start <=stop )
    range = Array.new 
    versions.each do |version|
      fits_stop  = Naturalsorter::Sorter.smaller_or_equal?(version.version, stop)
      fits_start = Naturalsorter::Sorter.bigger_or_equal?(version.version, start)
      if fits_start && fits_stop
        range.push(version)
      end
    end
    range
  end

  def get_versions_start_with(val)
    result = Array.new
    versions.each do |version|
      if version.version.match(/^#{val}/)
        result.push(version)
      end
    end
    result
  end

  def get_newest_but_not(value, range=false)
    filtered_versions = Array.new
    versions.each do |version|
      if !version.version.match(/^#{value}/)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = Product.get_newest_version_by_natural_order(filtered_versions)
    return get_newest_or_value(newest, value)
  end

  def get_greater_than(value, range = false)
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.bigger?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range 
    newest = Product.get_newest_version_by_natural_order(filtered_versions)
    return get_newest_or_value(newest, value)
  end

  def get_greater_than_or_equal(value, range = false)
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.bigger_or_equal?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range 
    newest = Product.get_newest_version_by_natural_order(filtered_versions)
    return get_newest_or_value(newest, value)
  end

  def get_smaller_than(value, range = false)
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.smaller?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range 
    newest = Product.get_newest_version_by_natural_order(filtered_versions)
    return get_newest_or_value(newest, value)
  end

  def get_smaller_than_or_equal(value, range = false)
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.smaller_or_equal?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = Product.get_newest_version_by_natural_order(filtered_versions)
    return get_newest_or_value(newest, value)
  end

  def versions_empty?
    versions.nil? || versions.size == 0 ? true : false
  end

  def wouldbenewest?(version)
    current = get_newest_version_by_natural_order
    return false if current.eql? version
    newest = Naturalsorter::Sorter.get_newest_version(current, version) 
    return true if version.eql? newest
    return false 
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
  rescue => e
    p " -- ERROR -- something went wrong --- #{e}"
    e.backtrace.each do |message|
      p "#{message}"
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

  def self.count_versions(lang)
    versions_count = 0 
    count = Product.where(language: lang).count()
    p "language: #{lang}, count: #{count}"
    pack = 100
    max = count / pack     
    (0..max).each do |i|
      skip = i * pack
      products = Product.where(language: "Java").skip(skip).limit(pack)
      products.each do |product|
        versions_count = versions_count + product.versions.count
        p "#{versions_count}"
      end
    end
    versions_count
  end

  ########### VERSIONS END ########################


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
      Product.attach_label_to_element(element, dep)
      element.version = dep.version_abs
      hash[dep.dep_prod_key] = element
    end
    return Product.fetch_deps(1, hash, Hash.new)
  end

  def self.fetch_deps(deep, hash, parent_hash)
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
        ele = Product.get_element_from_hash(new_hash, hash, parent_hash, key)
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
    rec_hash = Product.fetch_deps(deep, new_hash, parent_merged)
    merged_hash = parent_merged.merge(rec_hash)
    return merged_hash
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

  def self.correct_namespace
    products = Product.where(:prod_type => "Packagist" )
    products.each do |product|

      product.name = product.prod_key.gsub("php/", "")
      product.save

      deps = Dependency.all(conditions: { prod_key: product.prod_key } )
      deps.each do |dep|
        dep.name = dep.dep_prod_key.gsub("php/", "")
        dep.save
      end
      
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

  def main_scope
    if self.language.eql?("Ruby")
      return "runtime"
    elsif self.language.eql?("Java")
      return "compile"
    elsif self.language.eql?("Node.JS")
      return "compile"
    elsif self.language.eql?("PHP")
      return "require"
    end
  end

  def self.get_infographic_url_from_s3 filename
    AWS::S3::S3Object.url_for(filename, Settings.s3_infographics_bucket, :authenticated => false)
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

    def self.get_element_from_hash(new_hash, hash, parent_hash, key)
      element = new_hash[key]
      return element if !element.nil?
      element = hash[key]
      return element if !element.nil?
      element = parent_hash[key]
      return element
    end

    def self.attach_label_to_element(element, dep)
      element.text = dep.name
      if dep.version_for_label && !dep.version_for_label.empty? 
        element.text += ":#{dep.version_for_label}"
      end
    end

    def get_newest_or_value(newest, value)
      if newest.nil?
        version = Version.new 
        version.version = value  
        return version
      else 
        return newest  
      end
    end

end