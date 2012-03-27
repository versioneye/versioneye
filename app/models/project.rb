class Project

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :name, type: String
    
  field :project_type, type: String
  field :url, type: String
  field :file, type: String
  field :dep_number, type: Integer
  field :out_number, type: Integer, default: 0
  
  attr_accessor :dependencies
  
  def self.find_by_id(id)
    Project.first(conditions: { id: id} )
  end
  
  def self.find_by_user(user_id)
    Project.all(conditions: { user_id: user_id } )
  end
  
  def self.create_from_pom_url(url)
    doc = Nokogiri::HTML(open(url))
    if !doc.nil?
      project = Project.new
      project.dependencies = Array.new
      doc.xpath('//project/dependencies/dependency').each do |node|
        dependency = Projectdependency.new
        node.children.each do |child|  
          if child.name.casecmp("groupId") == 0
            dependency.group_id = child.text.strip 
          elsif child.name.casecmp("artifactId") == 0
            dependency.artifact_id = child.text.strip
          elsif child.name.casecmp("version") == 0
            dependency.version = child.text.strip
          end
        end
        dependency.name = dependency.artifact_id
        product = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id)
        if !product.nil?
          dependency.prod_key = product.prod_key
        end
        project.dependencies << dependency
      end
      project.dep_number = project.dependencies.count
      return project
    end
    nil
  end
  
  def fetch_dependencies
    Projectdependency.all(conditions: {project_id: self.id} )
  end
  
end