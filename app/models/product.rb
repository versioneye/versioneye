class Product

  require 'will_paginate'
  require 'will_paginate/array'

  include Mongoid::Document
  include Mongoid::Timestamps

  A_LANGUAGE_RUBY       = 'Ruby'
  A_LANGUAGE_PYTHON     = 'Python'
  A_LANGUAGE_NODEJS     = 'Node.JS'
  A_LANGUAGE_JAVA       = 'Java'
  A_LANGUAGE_PHP        = 'PHP'
  A_LANGUAGE_R          = 'R'
  A_LANGUAGE_JAVASCRIPT = 'JavaScript'
  A_LANGUAGE_CLOJURE    = 'Clojure'
  A_LANGUAGE_C          = 'C'
  A_LANGUAGE_OBJECTIVEC = 'Objective-C'
  A_LANGS_ALL           = [A_LANGUAGE_JAVA, A_LANGUAGE_RUBY, A_LANGUAGE_PYTHON, A_LANGUAGE_PHP, A_LANGUAGE_NODEJS, A_LANGUAGE_JAVASCRIPT, A_LANGUAGE_CLOJURE, A_LANGUAGE_R, A_LANGUAGE_OBJECTIVEC, A_LANGUAGE_C]
  A_LANGS_LANGUAGE_PAGE = [A_LANGUAGE_JAVA, A_LANGUAGE_RUBY, A_LANGUAGE_PYTHON, A_LANGUAGE_PHP, A_LANGUAGE_NODEJS, A_LANGUAGE_JAVASCRIPT, A_LANGUAGE_CLOJURE, A_LANGUAGE_R, A_LANGUAGE_OBJECTIVEC]
  A_LANGS_FILTER        = [A_LANGUAGE_JAVA, A_LANGUAGE_RUBY, A_LANGUAGE_PYTHON, A_LANGUAGE_PHP, A_LANGUAGE_NODEJS, A_LANGUAGE_JAVASCRIPT, A_LANGUAGE_CLOJURE, A_LANGUAGE_R, A_LANGUAGE_OBJECTIVEC]

  field :name         , type: String
  field :name_downcase, type: String
  field :prod_key     , type: String # Unique identifier inside a language
  field :prod_type    , type: String # Identifies the package manager
  field :language     , type: String
  field :version      , type: String # latest stable version

  field :group_id   , type: String # Maven specific
  field :artifact_id, type: String # Maven specific
  field :parent_id  , type: String # Maven specific

  field :description       , type: String
  field :description_manual, type: String

  field :downloads         , type: Integer, default: 0
  field :followers         , type: Integer, default: 0
  field :used_by_count     , type: Integer, default: 0 # Number of projects using this one.

  field :twitter_name, type: String

  field :reindex, type: Boolean, default: true

  # For indexing use task: rake db:mongoid:create_indexes
  index({followers:  -1}, {background: true})
  index({created_at: -1}, {background: true})
  index({updated_at: -1}, {background: true})
  index({updated_at: -1, language: -1}, {background: true})

  embeds_many :versions     # unsorted versions
  embeds_many :repositories

  has_and_belongs_to_many :users

  attr_accessor :released_days_ago, :released_ago_in_words, :released_ago_text
  attr_accessor :in_my_products, :dependencies_cache

  scope :by_language, ->(lang){where(language: lang)}

  def to_indexed_json # For ElasticSearch
    {
      :_id                => self.id.to_s,
      :_type              => 'product',
      :name               => self.name,
      :description        => self.description.to_s,
      :description_manual => self.description_manual.to_s,
      :followers          => self.followers,
      :used_by_count      => self.used_by_count,
      :group_id           => self.group_id.to_s,
      :prod_key           => self.prod_key,
      :language           => self.language,
      :prod_type          => self.prod_type
    }
  end

  def self.supported_languages
    Set[ A_LANGUAGE_RUBY, A_LANGUAGE_PYTHON, A_LANGUAGE_NODEJS,
         A_LANGUAGE_JAVA, A_LANGUAGE_PHP, A_LANGUAGE_R, A_LANGUAGE_JAVASCRIPT,
         A_LANGUAGE_CLOJURE, A_LANGUAGE_OBJECTIVEC]
  end

  def show_dependency_badge?
    self.language.eql?(A_LANGUAGE_JAVA)    or self.language.eql?(A_LANGUAGE_PHP) or
    self.language.eql?(A_LANGUAGE_RUBY)    or self.language.eql?(A_LANGUAGE_NODEJS) or
    self.language.eql?(A_LANGUAGE_CLOJURE) or self.language.eql?(A_LANGUAGE_OBJECTIVEC)
  end

  def to_s
    "<Product #{prod_key}(#{version}) ##{language}>"
  end

  def to_param
    Product.encode_prod_key self.prod_key
  end

  ######## SEARCH METHODS ####################

  def self.find_by_id id
    self.find id
  rescue => e
    Rails.logger.error e.message
    nil
  end

  def self.fetch_product lang, key
    return nil if lang.to_s.strip.empty? || key.to_s.strip.empty?
    return Product.find_by_key( key ) if lang.eql? 'package'
    product = Product.find_by_lang_key( lang, key )
    product = Product.find_by_lang_key_case_insensitiv( lang, key ) if product.nil?
    product
  end

  # legacy, still used by fall back search and API v1.0
  def self.find_by_key searched_key
    return nil if searched_key.to_s.strip.empty?
    Product.where(prod_key: searched_key).shift
  rescue => e
    Rails.logger.error e.message
    nil
  end

  def self.find_by_lang_key language, searched_key
    return nil if searched_key.to_s.strip.empty? || language.to_s.strip.empty?
    Product.where(language: language, prod_key: searched_key).shift
  end

  # This is slow!! Searches by regex are always slower than exact searches!
  def self.find_by_lang_key_case_insensitiv language, searched_key
    return nil if searched_key.to_s.strip.empty? || language.to_s.strip.empty?
    result = Product.where( prod_key: /^#{searched_key}$/i, language: /^#{language}$/i ).shift
  end

  def self.find_by_group_and_artifact group, artifact
    return nil if group.to_s.strip.empty? || artifact.to_s.strip.empty?
    Product.where( group_id: group, artifact_id: artifact ).shift
  end

  def self.by_prod_keys language, prod_keys
    if language.to_s.strip.empty? || prod_keys.nil? || prod_keys.empty? || !prod_keys.is_a?(Array)
      return Mongoid::Criteria.new(Product).where(:prod_key => "-1-1")
    end
    Product.where(:language => language, :prod_key.in => prod_keys)
  end

  ######## START VERSIONS ###################

  def sorted_versions
    Naturalsorter::Sorter.sort_version_by_method( versions, "version", false )
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
    versions
  end

  def version_by_number searched_version
    versions.each do |version|
      return version if version.to_s.eql?( searched_version )
    end
    nil
  rescue => e
    Rails.logger.error e
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

  def check_nil_version
    return nil if version
    return nil if versions.nil? or versions.empty?
    self.version = sorted_versions.first
    self.save
  end

  ######## ENCODE / DECODE ###################

  def self.encode_prod_key prod_key
    return "0" if prod_key.to_s.strip.empty?
    prod_key.to_s.gsub('/', ':')
  end

  def self.decode_prod_key prod_key
    return nil if prod_key.to_s.strip.empty?
    prod_key.to_s.gsub(':', '/')
  end

  def self.encode_language language
    return nil if language.to_s.strip.empty?
    language.to_s.gsub("\.", "").downcase
  end

  def self.decode_language language
    return nil if language.to_s.strip.empty?
    return A_LANGUAGE_NODEJS     if language.match(/^node/i)
    return A_LANGUAGE_PHP        if language.match(/^php/i)
    return A_LANGUAGE_JAVASCRIPT if language.match(/^JavaScript/i)
    return A_LANGUAGE_OBJECTIVEC if language.match(/^Objective-C/i)
    return language.capitalize
  end

  ########## UPDATE #############

  def update_used_by_count persist = true
    grouped = Dependency.where(:language => self.language, :dep_prod_key => self.prod_key).group_by(&:prod_key)
    count = grouped.count
    return nil if count == self.used_by_count
    self.used_by_count = count
    self.save if persist
  end

  def update_in_my_products array_of_product_ids
    self.in_my_products = array_of_product_ids.include?(_id.to_s)
  end

  ########## ELSE #############

  def description_summary
    if description && description_manual
      "#{description} \n \n #{description_manual}"
    elsif description && !description_manual
      return description
    elsif !description && description_manual
      return description_manual
    else
      ''
    end
  end

  def short_summary
    return get_summary(description, 125) if description
    get_summary(description_manual, 125)
  end

  def name_and_version
    "#{name} : #{version}"
  end

  def name_version limit
    nameversion = "#{name} (#{version})"
    if nameversion.length > limit
      "#{nameversion[0, limit]}.."
    else
      nameversion
    end
  end

  def language_esc lang = nil
    lang = self.language if lang.nil?
    Product.encode_language lang
  end

  def license_info
    licenses = self.licenses false
    return 'unknown' if licenses.nil? || licenses.empty?
    licenses.map{|a| a.name}.join(', ')
  end

  def comments
    Versioncomment.find_by_prod_key_and_version(self.language, self.prod_key, self.version)
  end

  # An artifact (product + version) can have multiple licenses
  # at the same time. That's not a bug!
  def licenses ignore_version = false
    License.for_product self, ignore_version
  end

  def developers
    Developer.find_by self.language, self.prod_key, version
  end

  def dependencies scope = nil
    dependencies_cache ||= {}
    scope = Dependency.main_scope(self.language) unless scope
    if dependencies_cache[scope].nil?
      dependencies_cache[scope] = Dependency.find_by_lang_key_version_scope( language, prod_key, version, scope )
    end
    dependencies_cache[scope]
  end

  def all_dependencies
    Dependency.find_by_lang_key_and_version( language, prod_key, version)
  end

  def http_links
    Versionlink.where(language: language, prod_key: self.prod_key, version_id: nil, link: /^http*/).asc(:name)
  end

  def http_version_links
    Versionlink.where(language: language, prod_key: self.prod_key, version_id: self.version, link: /^http*/ ).asc(:name)
  end

  def self.unique_languages_for_product_ids(product_ids)
    Product.where(:_id.in => product_ids).distinct(:language)
  end

  def to_url_path
    "/#{language_esc}/#{to_param}"
  end

  def version_to_url_param
    Version.encode_version version
  end

  def main_scope
    Dependency.main_scope self.language
  end

  private

    def get_summary text, size
      return '' if text.nil?
      return "#{text[0..size]}..." if text.size > size
      text[0..size]
    end

end
