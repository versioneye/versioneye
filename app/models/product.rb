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
      if Product.does_it_fit_stability version.version, stability
        return version 
      end
    end
    return nil
  end

  def self.does_it_fit_stability( version_number, stability )
    if stability.casecmp(Projectdependency::A_STABILITY_STABLE) == 0
      if ReleaseRecognizer.stable?( version_number )
        return true 
      end
    elsif stability.casecmp(Projectdependency::A_STABILITY_RC) == 0
      if ReleaseRecognizer.stable?( version_number ) || 
         ReleaseRecognizer.rc?( version_number )
        return true 
      end
    elsif stability.casecmp(Projectdependency::A_STABILITY_BETA) == 0
      if ReleaseRecognizer.stable?( version_number ) || 
         ReleaseRecognizer.rc?( version_number ) ||
         ReleaseRecognizer.beta?( version_number )
        return true 
      end
    elsif stability.casecmp(Projectdependency::A_STABILITY_ALPHA) == 0 
      if ReleaseRecognizer.stable?( version_number ) || 
         ReleaseRecognizer.rc?( version_number ) ||
         ReleaseRecognizer.beta?( version_number ) || 
         ReleaseRecognizer.alpha?( version_number )
        return true 
      end
    elsif stability.casecmp(Projectdependency::A_STABILITY_DEV) == 0 
      return true 
    else  
      return false 
    end
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

  def update_version_data
    return nil if self.versions.nil? || self.versions.empty?

    if self.versions.length < 2
      self.version = self.versions.first.version 
      self.save 
      return 
    end
    
    versions = sorted_versions
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

  def get_followers
    Follower.find_by_product(self.id.to_s)
  end

  def dependencies(scope)
    scope = main_scope if scope == nil 
    Dependency.find_by_key_version_scope(prod_key, version, scope)
  end

  def all_dependencies
    Dependency.find_by_key_and_version(prod_key, version)
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
  
  def get_links
    Versionlink.all(conditions: { prod_key: self.prod_key, version_id: nil}).asc(:name)
  end
  
  def get_version_links()
    Versionlink.all(conditions: { prod_key: self.prod_key, version_id: self.version}).asc(:name)
  end
  
  def self.get_hotest( count )
    Product.all().desc(:followers).limit( count )
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

  def self.get_unique_languages_filtered
    langs = Product.where(:language.in => ["Java", "Ruby", "Python", "PHP", "R", "Node.JS", "Clojure"]).distinct(:language)
  end

  def self.get_language_stat()
    data = []
    self.get_unique_languages_filtered.each do |lang|
      count = self.where(language: lang).count
      data << [lang, count]
    end
    data
  end

  def self.get_language_trend(start_date = nil, end_date =  nil)
    # returns cumulative trend of languages of given period, 
    # which by default is from 4th april to end of current month
    # Arguments have to Date object
   
    start_date = Date.new(2012, 4) if (start_date.nil? or not start_date.instance_of? Date)
    end_date = Date.today if (end_date.nil? or not end_date.instance_of? Date)
    results = {}
    xlabels = []
    first_run = true
    self.get_unique_languages_filtered.each do |lang|
      lang_vals = []
      i = 0
      iter_date = start_date
      while iter_date < end_date
        ncount = Product.where(language: lang, created_at: {"$lt" => iter_date}).count
        xlabels << "#{Date::ABBR_MONTHNAMES[iter_date.month]}/#{iter_date.year}" if first_run
        lang_vals << [i += 1, ncount]
        iter_date = iter_date >> 1
      end
      results[lang] = lang_vals.clone
      first_run = false;
    end    
    return {:xlabels => xlabels, :data => results}
  end

  def update_in_my_products(array_of_product_ids)
    self.in_my_products = array_of_product_ids.include?(_id.to_s)
  end
  
  def to_param
    Product.encode_product_key self.prod_key
  end

  def self.encode_product_key(prod_key)
    return "0" if prod_key.nil?
    prod_key.to_s.gsub("/", "--").gsub(".", "~")
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

  def self.encode_prod_key(prod_key)
    prod_key.gsub("/", "--").gsub(".", "~")
  end

  def self.decode_prod_key(prod_key)
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
