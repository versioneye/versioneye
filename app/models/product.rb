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
  A_LANGUAGE_JAVASCRIPT = "Javascript"
  A_LANGUAGE_CLOJURE    = "Clojure"
  A_LANGUAGE_C          = "C"
  A_LANGUAGE_OBJECTIVEC = "Objective-C"

  field :name         , type: String
  field :name_downcase, type: String
  field :prod_key     , type: String
  field :prod_type    , type: String
  field :language     , type: String

  field :group_id   , type: String
  field :artifact_id, type: String
  field :parent_id  , type: String

  field :description       , type: String
  field :description_manual, type: String
  field :downloads         , type: Integer
  field :followers         , type: Integer, default: 0
  field :used_by_count     , type: Integer, default: 0

  field :version     , type: String
  field :version_link, type: String

  field :icon        , type: String # TODO this hase to be remove in the long run
  field :twitter_name, type: String

  field :reindex, type: Boolean, default: true

  # For indexing use task: rake db:mongoid:create_indexes
  index({followers:  -1}, {background: true})
  index({created_at: -1}, {background: true})
  index({updated_at: -1}, {background: true})
  index({updated_at: -1, language: -1}, {background: true})

  embeds_many :versions
  embeds_many :repositories

  has_and_belongs_to_many :users
  # has_and_belongs_to_many :licenses

  # has_and_belongs_to_many :versionarchives
  # has_and_belongs_to_many :versionlinks
  # has_and_belongs_to_many :versioncomments

  attr_accessor :released_days_ago, :released_ago_in_words, :released_ago_text
  attr_accessor :version_uid, :in_my_products, :dependencies_cache

  scope :by_language, ->(lang){where(language: lang)}

  def delete
    false
  end

  def self.supported_languages
    Set[ A_LANGUAGE_RUBY, A_LANGUAGE_PYTHON, A_LANGUAGE_NODEJS,
         A_LANGUAGE_JAVA, A_LANGUAGE_PHP, A_LANGUAGE_R, A_LANGUAGE_JAVASCRIPT,
         A_LANGUAGE_CLOJURE, A_LANGUAGE_OBJECTIVEC]
  end

  # legacy, still used by fall back search
  def self.find_by_key(searched_key)
    return nil if searched_key.nil? || searched_key.strip == ""
    result = Product.where(prod_key: searched_key)
    return nil if (result.nil? || result.empty?)
    return result[0]
  end

  # TOOD R.R. check this
  def self.find_by_lang_key(language, searched_key)
    return nil if searched_key.nil? || searched_key.empty? || language.nil? || language.empty?
    Product.where(language: language, prod_key: searched_key).shift
  end

  # This is slow !! Searches by regex are always slower than exact searches!
  def self.find_by_lang_key_case_insensitiv(language, searched_key)
    return nil if searched_key.nil? || searched_key.empty? || language.nil? || language.empty?
    result = Product.where( prod_key: /^#{searched_key}$/i, language: /^#{language}$/i )
    return nil if (result.nil? || result.empty?)
    return result[0]
  end

  def self.fetch_product( lang, key )
    if lang.eql?("nodejs")
      lang = A_LANGUAGE_NODEJS
    end
    if lang.eql?("package")
      product = Product.find_by_key( key )
      return product if product
    end
    product = Product.find_by_lang_key( lang, key )
    if product.nil?
      product = Product.find_by_lang_key_case_insensitiv( lang, key )
    end
    product
  end

  # TODO R.R. check this
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
    Product.where( group_id: group, artifact_id: artifact ).shift
  end

  ######## ELASTIC SEARCH MAPPING ###################
  def to_indexed_json
    {
      :_id                => self.id.to_s,
      :_type              => "product",
      :name               => self.name,
      :description        => self.description.to_s,
      :description_manual => self.description_manual.to_s,
      :followers          => self.followers,
      :group_id           => self.group_id.to_s,
      :prod_key           => self.prod_key,
      :language           => self.language,
      :prod_type          => self.prod_type
    }
  end

  ######## START VERSIONS ###################

  def sorted_versions
    Naturalsorter::Sorter.sort_version_by_method( versions, "version", false )
  end

  def version_by_number( searched_version )
    return nil if searched_version.to_s.empty?
    return nil if versions.empty?
    versions.each do |version|
      return version if version.version.to_s.eql?( searched_version )
    end
    nil
  end

  def versions_empty?
    versions.nil? || versions.size == 0 ? true : false
  end

  def add_version(version_string, hash = {})
    unless version_by_number(version_string)
      version_hash = {:version => version_string}.merge(hash)
      version = Version.new(version_hash)
      versions.push( version )
    end
  end

  ######## END VERSIONS ###################

  def comments
    Versioncomment.find_by_prod_key_and_version(self.language, self.prod_key, self.version)
  end

  def language_esc(lang = nil)
    lang = self.language if lang.nil?
    Product.language_escape lang
  end

  def self.language_escape(lang)
    return "nodejs" if lang.eql?(A_LANGUAGE_NODEJS)
    return lang.downcase
  end

  def license_info
    licenses = self.licenses(false)
    return "unknown" if licenses.nil? || licenses.empty?
    licenses.map{|a| a.name}.join(", ")
  end

  # An artifact (product + version) can have multiple licenses
  # at the same time. That's not a bug!
  def licenses(ignore_version = false )
    License.for_product( self, ignore_version )
  end

  def developers
    Developer.find_by self.language, self.prod_key, version
  end

  def update_used_by_count( persist = true )
    count = Dependency.where(:dep_prod_key => self.prod_key).count
    return nil if count == self.used_by_count
    self.used_by_count = count
    self.save if persist
  end

  def dependencies(scope = nil)
    dependencies_cache ||= {}
    scope = Dependency.main_scope(self.language) unless scope
    if dependencies_cache[scope].nil?
      dependencies_cache[scope] = Dependency.find_by_lang_key_version_scope( language, prod_key, version, scope )
    end
    return dependencies_cache[scope]
  end

  def all_dependencies
    Dependency.find_by_lang_key_and_version( language, prod_key, version)
  end

  def self.random_product
    size = Product.count - 7
    Product.skip(rand( size )).first
  end

  def http_links
    Versionlink.where(language: language, prod_key: self.prod_key, version: nil, link: /^http*/).asc(:name)
  end

  def http_version_links
    Versionlink.where(language: language, prod_key: self.prod_key, version: self.version, link: /^http*/ ).asc(:name)
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
    Dependency.main_scope( self.language )
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
    prod_key.to_s.gsub("/", ":")
  end

  def self.encode_prod_key(prod_key)
    return nil if prod_key.nil?
    prod_key.gsub("/", ":")
  end

  def self.decode_prod_key(prod_key)
    return nil if prod_key.nil?
    prod_key.gsub(":", "/")
  end

  def self.encode_language(language)
    language.gsub("\.", "").downcase
  end

  def self.decode_language( language )
    return nil if language.nil?
    return A_LANGUAGE_NODEJS if language.match(/^node/i)
    return A_LANGUAGE_PHP if language.match(/^php/i)
    return A_LANGUAGE_JAVASCRIPT if language.match(/^JavaScript/i)
    return A_LANGUAGE_OBJECTIVEC if language.match(/^Objective-C/i)
    return language.capitalize
  end

  def to_url_path
    "/#{Product.encode_language(language)}/#{Product.encode_prod_key(prod_key)}"
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
    self.language.eql?(A_LANGUAGE_RUBY) or self.language.eql?(A_LANGUAGE_NODEJS) or
    self.language.eql?(A_LANGUAGE_CLOJURE)
  end

  private

    def get_summary text, size
      return "" if text.nil?
      return "#{text[0..size]}..." if text.size > size
      return text[0..size]
    end

end
