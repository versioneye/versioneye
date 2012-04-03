class Project

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :name, type: String
    
  field :project_type, type: String, :default => "Maven2"
  field :url, type: String
  field :s3, type: Boolean
  field :s3_filename, type: String
  field :dep_number, type: Integer
  field :out_number, type: Integer, default: 0
  
  attr_accessor :dependencies
  
  def self.find_by_id id
    Project.first(conditions: { id: id} )
  end
  
  def self.find_by_user user_id
    Project.all(conditions: { user_id: user_id } )
  end
  
  def self.create_from_file(project_type, url)
    project = nil
    if project_type.eql?("Maven2")
      project = Project.create_from_pom_url ( url )
    elsif project_type.eql?("RubyGems")
      project = Project.create_from_gemfile_url ( url )
    elsif project_type.eql?("PIP")
      project = Project.create_from_pip_url ( url )
    end
    project
  end
  
  def self.create_from_pom_url url
    return nil if url.nil?
    doc = Nokogiri::HTML(open(url))
    return nil if doc.nil?
      
    project = Project.new
    project.dependencies = Array.new
    
    properties = Hash.new
    doc.xpath('//project/properties').each do |node|
      node.children.each do |child|
          properties[child.name] = child.text.strip
      end  
    end
    
    doc.xpath('//project/dependencies/dependency').each do |node|
      dependency = Projectdependency.new
      
      node.children.each do |child|  
        if child.name.casecmp("groupId") == 0
          dependency.group_id = child.text.strip 
        elsif child.name.casecmp("artifactId") == 0
          dependency.artifact_id = child.text.strip
        elsif child.name.casecmp("version") == 0
          dependency.version = Project.get_variable_value_from_pom properties, child.text.strip 
        end
      end
      dependency.name = dependency.artifact_id
      
      product = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id)
      if !product.nil?
        dependency.prod_key = product.prod_key
      end
      
      dependency.update_outdated
      if dependency.outdated?
        project.out_number = project.out_number + 1
      end
      
      project.dependencies << dependency
    end
    
    project.dep_number = project.dependencies.count
    project
  end
  
  def self.create_from_pip_url(url)
    return nil if url.nil?
    uri = URI(url)
    txt = Net::HTTP.get(uri)
    return nil if txt.nil?
    
    project = Project.new
    project.dependencies = Array.new
    
    txt.each_line do |line|
      requirement = line.split("==")
      
      if requirement.empty?
        next
      end
      
      package = requirement[0]
      
      if package.strip.empty? 
        next
      end
      
      dependency = Projectdependency.new
      dependency.name = package
      
      if requirement.size == 2 
        version = requirement[1]
        dependency.version = version
      else
        dependency.version = "UNKNOWN"
      end
      
      product = Product.find_by_key("pip/#{package}")
      if !product.nil?
        dependency.prod_key = product.prod_key
      end
      dependency.update_outdated
      if dependency.outdated?
        project.out_number = project.out_number + 1
      end      
      project.dependencies << dependency
    end
    project.dep_number = project.dependencies.count
    project
  end
  
  def self.create_from_gemfile_url ( url )
    return nil if url.nil?
    uri = URI(url)
    gemfile = Net::HTTP.get(uri)
    return nil if gemfile.nil?
    
    project = Project.new
    project.dependencies = Array.new
    
    gemfile.each_line do |line|
      # if it starts not with gem skip the line
      line = line.strip
      if line.match(/^gem/).nil?
        next
      end
      line = line.gsub("gem ", "")
      elements = line.split(",")
      package = elements[0].strip
      package = package.gsub('"', '')
      package = package.gsub("'", "")
      
      dependency = Projectdependency.new
      dependency.name = package
      
      product = Product.find_by_key(package)
      if !product.nil?
        dependency.prod_key = product.prod_key
      end
      
      update_version_from_gemfile(elements, dependency, product)
      
      dependency.update_outdated
      if dependency.outdated?
        project.out_number = project.out_number + 1
      end      
      project.dependencies << dependency
    end
    project.dep_number = project.dependencies.count
    project
  end
  
  def fetch_dependencies
    self.dependencies = Projectdependency.all(conditions: {project_id: self.id} )
    self.dependencies
  end
  
  def self.get_variable_value_from_pom( properties, val )
    if val.include?("${") && val.include?("}")
      new_val = String.new(val)
      new_val.gsub!("${", "")
      new_val.gsub!("}", "")
      new_val.downcase!
      value = properties[new_val]
      return val if value.nil? || value.empty?
      return value 
    else 
      return val  
    end
  end
  
  def self.update_version_from_gemfile(elements, dependency, product)
    version = elements[1]
    if (!version.nil?)
      version = version.strip
      version = version.gsub('"', '')
      version = version.gsub("'", "")
      if version.match(/^:require/)
        update_dep_version_with_product(dependency, product)
      elsif version.match(/^>/)
        update_dep_version_with_product(dependency, product)
      elsif version.match(/^~>/)
        ver = version.gsub("~>", "")
        if !product.nil? && Project.is_version_current?(ver, product.version)
          dependency.version = product.version
        else 
          dependency.version = ver
        end
      elsif version.match(/^http/)
        dependency.version = "UNKNOWN"
      else
        dependency.version = version
      end
    else 
      update_dep_version_with_product(dependency, product)
    end
  end
  
  # TODO move this to external lib
  def self.is_version_current?(version, current_version)
    versions = version.split(".")
    currents = current_version.split(".")
    min_length = versions.size
    if currents.size < min_length
      min_length = currents.size
    end
    min_length = min_length - 2
    if min_length < 0
      min_length = 0
    end      
    (0..min_length).each do |z|
      ver = versions[z]
      cur = currents[z]
      if (cur > ver)
        return false
      end
    end
    if currents.size < versions.size
      ver = versions[min_length + 1]
      cur = currents[min_length + 1]
      if cur > ver
        return false
      end
    end
    true
  end
  
  private 
  
    def self.update_dep_version_with_product( dependency, product )
      if !product.nil?
        dependency.version = product.version
      else
        dependency.version = "UNKNOWN"
      end
      dependency
    end
  
end