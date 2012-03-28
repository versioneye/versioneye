class Project

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :name, type: String
    
  field :project_type, type: String
  field :url, type: String
  field :s3, type: Boolean
  field :dep_number, type: Integer
  field :out_number, type: Integer, default: 0
  
  attr_accessor :dependencies
  
  def self.find_by_id id
    Project.first(conditions: { id: id} )
  end
  
  def self.find_by_user user_id
    Project.all(conditions: { user_id: user_id } )
  end
  
  def self.create_from_pom_url url
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
  
end