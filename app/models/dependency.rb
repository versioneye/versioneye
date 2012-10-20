class Dependency

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :version, type: String  
  field :group_id, type: String
  field :artifact_id, type: String
  field :dep_prod_key, type: String     # this is the prod_key of the dependency (Foreign Key)
  field :scope, type: String

  field :prod_key, type: String         # This dependency belongs to this prod_key
  field :prod_version, type: String     # This dependency belongs to this version of prod_key

  field :prod_type, type: String, :default => "RubyGem"
  field :language, type: String, :default => "Ruby"
  
  def self.find_by_key_version_scope(prod_key, version, scope)
    Dependency.all(conditions: { prod_key: prod_key, prod_version: version, scope: scope } )
  end

  def self.find_by_key_and_version(prod_key, version)
    Dependency.all(conditions: { prod_key: prod_key, prod_version: version } )
  end

  def self.find_by(name, version, dep_prod_key, prod_key, prod_version)
    dependencies = Dependency.where(name: name, version: version, dep_prod_key: dep_prod_key, prod_key: prod_key, prod_version: prod_version)
    return nil if dependencies.nil? || dependencies.empty? 
    dependencies[0]
  end

  def version_for_url
    return "0" if version.nil?
    url_param = String.new(version)
    if prod_type.eql?("RubyGem")
      url_param = String.new(gem_version_abs)
    end
    url_param.gsub!("/","--")
    url_param.gsub!(".","~")
    "#{url_param}"    
  end

  def version_abs
    return "0" if version.nil?
    abs_version = String.new(version)
    if prod_type.eql?("RubyGem")
      abs_version = String.new(gem_version_abs)
    end
    abs_version
  end

  def version_for_label
    return gem_version if prod_type.eql?("RubyGem")
    return version
  end

  def dep_prod_key_for_url
    return "0" if dep_prod_key.nil?
    url_param = String.new(dep_prod_key)
    url_param.gsub!("/","--")
    url_param.gsub!(".","~")
    "#{url_param}"    
  end

  def gem_version
    ver = String.new(version)
    ver = ver.gsub(" ", "")
    if ver.match(/^=/)
      ver = ver.gsub("=", "")
    end
    ver
  end

  def gem_version_abs
    ver = String.new(version)
    product = Product.find_by_key(self.dep_prod_key)
    dependency = Projectdependency.new
    GemfileParser.parse_requested_version(ver, dependency, product)
    dependency.version_requested
  end
  
end