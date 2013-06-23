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

  field :name         , type: String
  field :name_downcase, type: String
  field :prod_key     , type: String
  field :prod_type    , type: String
  field :language     , type: String

  field :group_id   , type: String
  field :artifact_id, type: String
  field :parent_id  , type: String

  field :authors           , type: String
  field :description       , type: String
  field :description_manual, type: String
  field :link              , type: String
  field :downloads         , type: Integer
  field :followers         , type: Integer, default: 0
  field :last_release      , type: Integer, default: 0
  field :used_by_count     , type: Integer, default: 0

  field :license           , type: String
  field :licenseLink       , type: String
  field :license_manual    , type: String
  field :licenseLink_manual, type: String

  field :version     , type: String
  field :version_link, type: String

  field :like_overall, type: Integer, default: 0
  field :like_docu   , type: Integer, default: 0
  field :like_support, type: Integer, default: 0

  field :icon        , type: String
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
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
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
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    Mongoid::Criteria.new(Product, {_id: -1})
  end

  def self.find_by_name(searched_name)
    if (searched_name.nil? || searched_name.strip == "")
      return nil
    end
    Product.where(name_downcase: /^#{searched_name}/)
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
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
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
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
    self.find( id )
  rescue => e
    Rails.logger.error e.message
    nil
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

  ######## START VERSIONS ###################

  def sorted_versions
    Naturalsorter::Sorter.sort_version_by_method( versions, "version", false )
  end

  def version_by_number( searched_version )
    versions.each do |version|
      return version if version.version.eql?(searched_version)
    end
    nil
  end

  def versions_empty?
    versions.nil? || versions.size == 0 ? true : false
  end

  ######## END VERSIONS ###################

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

  def dependencies(scope = nil)
    scope = main_scope if scope == nil
    Dependency.find_by_key_version_scope(prod_key, version, scope)
  end

  def all_dependencies
    Dependency.find_by_key_and_version(prod_key, version)
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
      return Dependency::A_SCOPE_RUNTIME
    elsif self.language.eql?("Java")
      return Dependency::A_SCOPE_COMPILE
    elsif self.language.eql?("Node.JS")
      return Dependency::A_SCOPE_COMPILE
    elsif self.language.eql?("PHP")
      return Dependency::A_SCOPE_REQUIRE
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
    prod_key.to_s.gsub("/", "--")
  end

  def self.encode_prod_key(prod_key)
    return nil if prod_key.nil?
    prod_key.gsub("/", "--")
  end

  def self.decode_prod_key(prod_key)
    return nil if prod_key.nil?
    prod_key.gsub("--", "/")
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

end
