class Dependency

  require 'will_paginate/array'

  # This Model describes the relationship between 2 products/packages
  # This Model describes 1 dependency of a package to another package

  include Mongoid::Document
  include Mongoid::Timestamps

  A_SCOPE_COMPILE     = 'compile'
  A_SCOPE_RUNTIME     = 'runtime'
  A_SCOPE_REQUIRE     = 'require'
  A_SCOPE_PROVIDED    = 'provided'
  A_SCOPE_DEVELOPMENT = 'development'
  A_SCOPE_TEST        = 'test'

  # This attributes describe to which product
  # this dependency belongs to. Parent!
  field :prod_type   , type: String,  :default => Project::A_TYPE_RUBYGEMS
  field :language    , type: String,  :default => Product::A_LANGUAGE_RUBY
  field :prod_key    , type: String   # This dependency belongs to this prod_key
  field :prod_version, type: String   # This dependency belongs to this version of prod_key

  # This attributes describe the dependency itself!
  field :dep_prod_key, type: String   # prod_key of the dependency (Foreign Key)
  field :version     , type: String   # version of the dependency. This is the unfiltered version string. It is not parsed yet.
  field :name        , type: String
  field :group_id    , type: String   # Maven specific
  field :artifact_id , type: String   # Maven specific
  field :scope       , type: String
  field :known       , type: Boolean  # known or unknown dependency

  # The current version of the product, which this dep is referencing
  field :current_version, type: String

  def self.find_by_lang_key_and_version( lang, prod_key, version)
    Dependency.where( language: lang, prod_key: prod_key, prod_version: version )
  end

  def self.find_by_lang_key_version_scope(lang, prod_key, version, scope)
    if scope
      return Dependency.where( language: lang, prod_key: prod_key, prod_version: version, scope: scope )
    else
      return Dependency.where( language: lang, prod_key: prod_key, prod_version: version )
    end
  end

  def self.find_by(language, prod_key, prod_version, dep_name, dep_version, dep_prod_key)
    dependencies = Dependency.where(language: language, prod_key: prod_key, prod_version: prod_version, name: dep_name, version: dep_version, dep_prod_key: dep_prod_key)
    return nil if dependencies.nil? || dependencies.empty?
    dependencies[0]
  end

  def self.references language, prod_key, page
    per_page = 30
    page     = 0 if page.to_s.empty?
    page     = page.to_i - 1 if page.to_i > 0
    skip     = page.to_i * per_page

    count = Dependency.collection.aggregate(
      { '$match' => { :language => language, :dep_prod_key => prod_key } },
      { '$group' => { :_id => '$prod_key' } }
    ).count

    deps = Dependency.collection.aggregate(
      { '$match' => { :language => language, :dep_prod_key => prod_key } },
      { '$group' => { :_id => '$prod_key' } },
      { '$skip'  => skip },
      { '$limit' => per_page }
    )
    prod_keys = deps.map{|dep| dep['_id'] }
    {:prod_keys => prod_keys, :count => count}
  end

  def product
    if group_id && artifact_id
      return Product.find_by_group_and_artifact( group_id, artifact_id )
    end
    Product.fetch_product( language, dep_prod_key )
  end

  def parent_product
    Product.fetch_product( language, prod_key )
  end

  def language_escaped
    return "nodejs" if self.language.eql? Product::A_LANGUAGE_NODEJS
    language.downcase
  end

  def update_known
    product    = self.product
    self.known = !product.nil?
    self.save()
  end

  def update_known_if_nil
    self.update_known() if self.known.nil? || self.known == false
  end

  def self.main_scope( language )
    if language.eql?( Product::A_LANGUAGE_RUBY )
      return A_SCOPE_RUNTIME
    elsif language.eql?( Product::A_LANGUAGE_JAVA ) || language.eql?( Product::A_LANGUAGE_CLOJURE )
      return A_SCOPE_COMPILE
    elsif language.eql?( Product::A_LANGUAGE_NODEJS )
      return A_SCOPE_COMPILE
    elsif language.eql?( Product::A_LANGUAGE_PHP )
      return A_SCOPE_REQUIRE
    end
  end

  def version_parsed
    return "unknown" if version.nil? || version.empty?
    abs_version = String.new(version)
    if prod_type.eql?( Project::A_TYPE_RUBYGEMS )
      abs_version = String.new( gem_version_parsed )
    elsif prod_type.eql?( Project::A_TYPE_COMPOSER )
      abs_version = String.new( packagist_version_parsed )
    elsif prod_type.eql?( Project::A_TYPE_NPM )
      abs_version = String.new( npm_version_parsed )
    elsif prod_type.eql?( Project::A_TYPE_COCOAPODS )
      abs_version = String.new( cocoapods_version_parsed )
    end
    # TODO cases for java
    abs_version
  end

  def gem_version_parsed
    version_string = String.new(version)
    product        = Product.fetch_product( self.language, self.dep_prod_key )
    dependency     = Projectdependency.new
    parser         = GemfileParser.new
    parser.parse_requested_version(version_string, dependency, product)
    dependency.version_requested
  end

  def cocoapods_version_parsed
    version_string = String.new(version)
    product        = Product.fetch_product( self.language, self.dep_prod_key )
    dependency     = Projectdependency.new
    CocoapodsPackageManager.parse_requested_version(version_string, dependency, product)
    dependency.version_requested
  end

  def packagist_version_parsed
    lang = self.language
    if self.dep_prod_key.eql?("php/php") or self.dep_prod_key.eql?("php")
      lang = Product::A_LANGUAGE_C
    end
    version_string = String.new(version)
    product        = Product.fetch_product( lang, self.dep_prod_key )
    dependency     = Projectdependency.new
    parser         = ComposerParser.new
    parser.parse_requested_version(version_string, dependency, product)
    dependency.version_requested
  end

  def npm_version_parsed
    version_string = String.new( version )
    product        = Product.fetch_product( self.language, self.dep_prod_key )
    dependency     = Projectdependency.new
    parser         = PackageParser.new
    parser.parse_requested_version( version_string, dependency, product )
    dependency.version_requested
  end

  def dep_prod_key_for_url
    Product.encode_product_key dep_prod_key
  end

  def version_for_url
    url_param = version_parsed
    Version.encode_version( url_param )
  rescue => e
    Rails.logger.error e.message
    return self.version
  end

  def to_s
    "Dependency - #{language}:#{prod_key}:#{prod_version} depends on #{dep_prod_key}:#{version}"
  end

end
