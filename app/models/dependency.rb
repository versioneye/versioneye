class Dependency

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes # Need for type: DateTime 

  field :name, type: String
  field :version, type: String  
  field :group_id, type: String
  field :artifact_id, type: String
  field :dep_prod_key, type: String     # this is the prod_key of the dependency
  field :scope, type: String

  field :prod_key, type: String         # This dependency belongs to this prod_key
  field :prod_version, type: String     # This dependency belongs to this version of prod_key

  field :prod_type, type: String, :default => "RubyGem"
  field :language, type: String, :default => "Ruby"
  
  def self.find_by_key_version_scope(prod_key, version, scope)
    Dependency.all(conditions: { prod_key: prod_key, prod_version: version, scope: scope } )
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

  def self.data_correction
    dependencies = Dependency.all(conditions: {group_id: /^\$/i})
    dependencies.each do |dep|
      p "before #{dep.dep_prod_key}"
      product = Product.find_by_key(dep.prod_key)
      dep.group_id = product.group_id
      dep.dep_prod_key = "#{dep.group_id}/#{dep.artifact_id}"
      dep.save
      p "after #{dep.dep_prod_key}"
    end
    # dependencies = Dependency.all(conditions: {artifact_id: /^\$/i})
    # dependencies.each do |dep|
    #   p "before #{dep.dep_prod_key}"
    #   product = Product.find_by_key(dep.prod_key)
    #   dep.artifact_id = product.artifact_id
    #   dep.dep_prod_key = "#{dep.group_id}/#{dep.artifact_id}"
    #   dep.save
    #   p "after #{dep.dep_prod_key}"
    # end
  end

  def gem_version_abs
    ver = String.new(version)
    ver = ver.gsub(" ", "")
    if ver.match(/^=/)
      ver = ver.gsub("=", "")
      return ver
    elsif ver.match(/^~>/)
      fuzzy = ""
      ver = ver.gsub("~>", "")
      version_elements = ver.split(".")
      shrinked_count = version_elements.count - 2
      shrinked_elements = version_elements[0..shrinked_count]
      fuzzy = shrinked_elements.join(".")
      versions = Array.new
      product = Product.find_by_key(dep_prod_key)
      product.versions.each do |p_version|
        if p_version.version.match(/^#{fuzzy}/)
          versions << p_version
        end
      end
      versions = Naturalsorter::Sorter.sort_version_by_method_desc(versions, "version")
      return versions.first.version
    elsif ver.match(/^>=/) || ver.match(/^>/)
      product = Product.find_by_key(dep_prod_key)
      return product.get_newest_version_by_natural_order
    end
    ver
  end
  
end