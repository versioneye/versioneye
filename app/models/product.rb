class Product

  require 'will_paginate/array'

  include Mongoid::Document
  include Mongoid::Timestamps

  A_LANGUAGE_RUBY       = "Ruby"
  A_LANGUAGE_PYTHON     = "Python"
  A_LANGUAGE_NODEJS     = "Node.JS"
  A_LANGUAGE_JAVA       = "Java"
  A_LANGUAGE_PHP        = "PHP"
  A_LANGUAGE_R          = "R"
  A_LANGUAGE_JAVASCRIPT = "JavaScript"
  A_LANGUAGE_CLOJURE    = "Clojure"

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
  field :last_release, type: Integer, default: 0
  field :used_by_count, type: Integer, default: 0
  
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
  has_and_belongs_to_many :users
  # versionarchives
  # versionlinks
  # versionchanges
  # versioncomments

  attr_accessor :in_my_products, :version_uid, :last_crawle_date, :released_days_ago

  def delete
    false
  end

  # languages have to be an array of strings. 
  def self.find_by(query, description = nil, group_id = nil, languages=nil, limit=300)
    searched_name = nil 
    if query 
      searched_name = String.new( query.gsub(" ", "-") )
    end
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
  rescue => e 
    p "ERROR in find_by - #{e}"
    Mongoid::Criteria.new(Product, {_id: -1})
  end

  # languages have to be an array of strings. 
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
    result = nil
    id = id.to_s if id.is_a?(BSON::ObjectId)

    return nil if id.nil? or id.empty?

    if Product.where(_id: id).exists?
      result = Product.find(id)
    end
    result
  end
  
  def self.find_by_group_and_artifact(group, artifact)
    Product.where( group_id: group, artifact_id: artifact )[0]
  end
  
  ######## ELASTIC SEARCH MAPPING ###################
  def to_indexed_json
    {
      :_id => self.id.to_s,
      :_type => "product",
      :name => self.name,
      :description => self.description ? self.description : "" ,
      :description_manual => self.description_manual ? self.description_manual : "" , 
      :language => self.language,
      :followers => self.followers,
      :group_id => self.group_id ? self.group_id : "", 
      :prod_key => self.prod_key,
      :prod_type => self.prod_type
    }
  end 

  ########### VERSIONS START ########################

  def sorted_versions
    Naturalsorter::Sorter.sort_version_by_method_desc( versions, "version" )
  end

  def newest_version( stability = "stable" )
    versions = self.sorted_versions
    return nil if versions.nil? || versions.empty? 
    versions.each do |version|
      if VersionTagRecognizer.does_it_fit_stability? version.version, stability
        return version 
      end
    end
    return versions.first
  end

  def newest_version_number( stability = "stable" )
    version = newest_version( stability )
    return nil if version.nil? 
    return version.version
  end

  def self.newest_version_from(versions, stability = "stable")
    return nil if !versions || versions.empty?
    product = Product.new({:versions => versions})
    product.newest_version( stability )
  end

  def newest_version_from_wildcard( version_start, stability = "stable" )
    versions = versions_start_with( version_start )
    product = Product.new({:versions => versions}) 
    return product.newest_version_number stability
  end

  def version_by_number( searched_version )
    versions.each do |version|
      return version if version.version.eql?(searched_version)
    end
    nil
  end 

  def self.version_approximately_greater_than_starter(value)
    if value.match(/\.0$/)
      new_end = value.length - 2
      return value[0..new_end]
    else 
      return "#{value}."
    end
  end

  def version_tilde_newest(value)
    new_st = "#{value}"
    if value.match(/./)
      splits = value.split(".")
      new_end = splits.size - 2
      new_slice = splits[0..new_end]
      new_st = new_slice.join(".")
    end
    starter = "#{new_st}."
    
    versions_group1 = self.versions_start_with( starter )
    versions = Array.new
    versions_group1.each do |version| 
      if Naturalsorter::Sorter.bigger_or_equal?(version.version, value)
        versions.push(version)
      end
    end
    Product.newest_version_from(versions)
  end

  def version_range(start, stop)
    # get all versions from range ( >=start <=stop )
    range = Array.new 
    versions.each do |version|
      fits_stop  = Naturalsorter::Sorter.smaller_or_equal?( version.version, stop  )
      fits_start = Naturalsorter::Sorter.bigger_or_equal?(  version.version, start )
      if fits_start && fits_stop
        range.push(version)
      end
    end
    range
  end

  def versions_start_with(val)
    result = Array.new
    versions.each do |version|
      if version.version.match(/^#{val}/)
        result.push(version)
      end
    end
    result
  end

  def newest_but_not(value, range=false)
    filtered_versions = Array.new
    versions.each do |version|
      if !version.version.match(/^#{value}/)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = Product.newest_version_from(filtered_versions)
    return get_newest_or_value(newest, value)
  end

  def greater_than(value, range = false)
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.bigger?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range 
    newest = Product.newest_version_from(filtered_versions)
    return get_newest_or_value(newest, value)
  end

  def greater_than_or_equal(value, range = false)
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.bigger_or_equal?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range 
    newest = Product.newest_version_from(filtered_versions)
    return get_newest_or_value(newest, value)
  end

  def smaller_than(value, range = false)
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.smaller?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range 
    newest = Product.newest_version_from(filtered_versions)
    return get_newest_or_value(newest, value)
  end

  def smaller_than_or_equal(value, range = false)
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.smaller_or_equal?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = Product.newest_version_from(filtered_versions)
    return get_newest_or_value(newest, value)
  end

  def versions_empty?
    versions.nil? || versions.size == 0 ? true : false
  end

  def wouldbenewest?(version)
    current = newest_version_number()
    return false if current.eql? version
    newest = Naturalsorter::Sorter.get_newest_version(current, version) 
    return true if version.eql? newest
    return false 
  end

  def update_version_data( persist = true )
    return nil if self.versions.nil? || self.versions.empty?
    newest_stable_version = self.newest_version
    return nil if newest_stable_version.version.eql?(self.version)
    self.version = newest_stable_version.version
    self.version_link = newest_stable_version.link
    self.save if persist
    # p " udpate #{self.name} with version #{self.version}"
  rescue => e
    p " -- ERROR -- something went wrong -- #{self.prod_key} --- #{e}"
    e.backtrace.each do |message|
      p "#{message}"
    end
  end

  def versions_with_rleased_date
    return nil if versions.nil? || versions.empty?
    new_versions = Array.new 
    versions.each do |version| 
      new_versions << version if !version.released_at.nil?
    end
    new_versions
  end

  def average_release_time
    return nil if versions.nil? || versions.empty? || versions.size < 3
    released_versions = versions_with_rleased_date
    return nil if released_versions.nil? || released_versions.empty? || released_versions.size < 3
    sorted_versions = released_versions.sort! { |a,b| a.released_at <=> b.released_at }
    first = sorted_versions.first.released_at
    last = sorted_versions.last.released_at
    return nil if first.nil? || last.nil?
    diff = last.to_i - first.to_i 
    diff_days = diff / 60 / 60 / 24
    average = diff_days / sorted_versions.size 
    average
  rescue => e 
    p "Exception in average_release_time: #{e}" 
    nil 
  end

  def copy_released_versions
    new_versions = Array.new 
    versions.each do |version| 
      new_versions << version if version.released_string
    end
    self.versions = new_versions
    self.save
  end

  ########### VERSIONS END ########################

  def comments
    Versioncomment.find_by_prod_key_and_version(self.prod_key, self.version)
  end
  
  def license_info
    if self.license.nil? || self.license.empty? || self.license.eql?("unknown")
      return self.license_manual
    end
    return self.license
  end

  def license_link_info 
    return self.licenseLink_manual unless self.licenseLink
    return self.licenseLink
  end

  def update_used_by_count( persist = true )
    self.used_by_count = Dependency.where(:dep_prod_key => self.prod_key).count
    self.save if persist 
  end

  def dependencies(scope)
    scope = main_scope if scope == nil 
    Dependency.find_by_key_version_scope(prod_key, version, scope)
  end

  def all_dependencies
    Dependency.find_by_key_and_version(prod_key, version)
  end

  # TODO write tests for this 
  def dependencies_outdated?(scope = nil )
    deps = self.dependencies( scope )
    return false if deps.nil? || deps.empty?
    deps.each do |dep| 
      return true if dep.outdated? 
    end
    return false
  end

  def dependency_circle(scope)
    if scope == nil 
      scope = main_scope
    end
    hash = Hash.new
    dependencies = Array.new 
    if scope.eql?("all")
      dependencies = Dependency.find_by_key_and_version(prod_key, version)
    else 
      dependencies = Dependency.find_by_key_version_scope(prod_key, version, scope)
    end
    dependencies.each do |dep| 
      if dep.name.nil? || dep.name.empty?
        p "dep name is nil! #{dep.dep_prod_key}"
        next
      end      
      element = CircleElement.new
      element.init
      element.dep_prod_key = dep.dep_prod_key
      element.version = dep.version_parsed
      element.level = 0
      Product.attach_label_to_element(element, dep)
      hash[dep.dep_prod_key] = element
    end
    return Product.fetch_deps(1, hash, Hash.new)
  end

  def self.fetch_deps(deep, hash, parent_hash)
    return hash if hash.empty? 
    new_hash = Hash.new
    hash.each do |prod_key, element|
      product = Product.find_by_key( prod_key )
      if product.nil?
        p "#{element.dep_prod_key} #{element.version} not found!"
        next
      end
      if (element.version && !element.version.eql?("") && !element.version.eql?("0"))
        product.version = element.version
      end
      dependencies = product.dependencies(nil)
      dependencies.each do |dep|
        if dep.name.nil? || dep.name.empty?
          p "dep name is nil! #{dep.dep_prod_key}"
          next
        end
        key = dep.dep_prod_key
        ele = Product.get_element_from_hash(new_hash, hash, parent_hash, key)
        if ele
          ele.connections << "#{element.dep_prod_key}"
        else 
          new_element = CircleElement.new
          new_element.init
          new_element.dep_prod_key = dep.dep_prod_key
          new_element.level = deep
          attach_label_to_element(new_element, dep)
          new_element.connections << "#{element.dep_prod_key}"
          new_element.version = dep.version_parsed
          new_hash[dep.dep_prod_key] = new_element
        end
        element.connections << "#{key}"
        element.dependencies << "#{key}"
      end
    end
    parent_merged = hash.merge(parent_hash)
    deep += 1 
    rec_hash = Product.fetch_deps(deep, new_hash, parent_merged)
    merged_hash = parent_merged.merge(rec_hash)
    return merged_hash
  end

  def self.random_product
    size = Product.count - 7
    Product.skip(rand( size )).first 
  end
  
  def http_links
    Versionlink.all(conditions: { prod_key: self.prod_key, version_id: nil, link: /^http*/}).asc(:name)
  end
  
  def http_version_links
    Versionlink.all(conditions: { prod_key: self.prod_key, version_id: self.version, link: /^http*/ }).asc(:name)
  end
  
  def self.get_hotest( count )
    Product.all().desc(:followers).limit( count )
  end

  # TODO test
  def self.get_unique_languages_for_product_ids(product_ids)
    Product.where(:_id.in => product_ids).distinct(:language)
  end

  def update_in_my_products(array_of_product_ids)
    self.in_my_products = array_of_product_ids.include?(_id.to_s)
  end
  
  def to_param
    Product.encode_product_key self.prod_key
  end
  
  def version_to_url_param
    Product.encode_product_key version    
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

  def self.downcase_array(arr)
    array_dwoncase = Array.new 
    arr.each do |element|
      array_dwoncase.push element.downcase
    end
    array_dwoncase
  end

  def self.encode_product_key(prod_key)
    return "0" if prod_key.nil?
    prod_key.to_s.gsub("/", "--").gsub(".", "~")
  end

  def self.encode_prod_key(prod_key)
    return nil if prod_key.nil? 
    prod_key.gsub("/", "--").gsub(".", "~")
  end

  def self.decode_prod_key(prod_key)
    return nil if prod_key.nil? 
    prod_key.gsub("--", "/").gsub("~", ".")
  end

  def description_summary
    if description && description_manual
      return "#{description} \n \n #{description_manual}"
    elsif description && !description_manual 
      return description
    elsif !description && description_manual
      return description_manual
    else 
      return ""
    end
  end

  def short_summary
    return get_summary(description, 125) if description
    return get_summary(description_manual, 125)
  end

  def show_dependency_badge? 
    self.language.eql?(A_LANGUAGE_JAVA) or self.language.eql?(A_LANGUAGE_PHP) or 
    self.language.eql?(A_LANGUAGE_RUBY) or self.language.eql?(A_LANGUAGE_NODEJS)
  end

  private

    def get_summary text, size 
      return "" if text.nil? 
      return "#{text[0..size]}..." if text.size > size 
      return text[0..size]
    end

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

    # TODO test and move 
    def self.attach_label_to_element(element, dep)
      element.text = "#{dep.name}:#{dep.version}"
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
