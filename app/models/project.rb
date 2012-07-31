class Project

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :name, type: String
    
  field :project_type, type: String, :default => "Maven2"
  field :url, type: String
  field :s3, type: Boolean, :default => false
  field :s3_filename, type: String
  field :github, type: Boolean, :default => false
  field :github_project, type: String
  field :dep_number, type: Integer
  field :out_number, type: Integer, default: 0
  
  attr_accessor :dependencies
  
  def self.find_by_id id
    Project.first(conditions: { id: id} )
  end
  
  def self.find_by_user user_id
    Project.all(conditions: { user_id: user_id } )
  end

  def fetch_dependencies
    self.dependencies = Projectdependency.all(conditions: {project_id: self.id} ).desc(:outdated).asc(:prod_key)
    self.dependencies
  end

  def user
    return User.find_by_id(user_id) if user_id
    return nil
  end

  def get_outdated_dependencies
    fetch_dependencies
    outdated_dependencies = Array.new
    self.dependencies.each do |dep|
      outdated_dependencies << dep if dep.outdated
    end
    outdated_dependencies
  end

  def get_known_dependencies
    fetch_dependencies
    known_dependencies = Array.new
    self.dependencies.each do |dep|
      known_dependencies << dep if dep.prod_key
    end
    known_dependencies
  end  

  def self.remove_dependencies(project)
    project.fetch_dependencies
    project.dependencies.each do |dep|
      dep.remove
    end
  end

  def self.save_dependencies(project, dependencies)
    project.dependencies = Array.new
    dependencies.each do |dep|
      project.dependencies << dep
      dep.project_id = project.id.to_s
      dep.user_id = project.user_id
      dep.save
    end
  end

  def self.update_dependencies
    projects = Project.all()
    projects.each do |project|
      Project.process_project ( project )  
    end
  end

  def self.process_project( project )
    if project.user_id.nil?
      return nil
    end
    if project.github
      Project.update_from_github( project )
    elsif project.s3 
      project.url = Project.get_project_url_from_s3( project.s3_filename )
    end
    p "user: #{project.user.username}  #{project.name} url: #{project.url}"
    p " - old: deps: #{project.dep_number} - out: #{project.out_number}"
    new_project = Project.create_from_file( project.project_type, project.url )
    p " - new: deps: #{new_project.dep_number} - out: #{new_project.out_number}"
    if new_project.dependencies && !new_project.dependencies.empty? 
      Project.remove_dependencies(project)
      Project.save_dependencies(project, new_project.dependencies)
      project.out_number = new_project.out_number
      project.dep_number = new_project.dep_number
      project.save
      if project.out_number > 0
        ProjectMailer.projectnotification_email(project).deliver
      end
    end
  rescue => e
    p "ERROR in proccess_project #{e}"
    nil
  end

  def self.update_from_github( project )
    github_project = project.github_project
    current_user = project.user
    sha = Project.get_repo_sha_from_github( github_project, current_user.github_token )
    project_info = Project.get_project_info_from_github( github_project, sha, current_user.github_token )
    if project_info.empty?
      return nil
    end
    s3_infos = Project.fetch_file_from_github(project_info['url'], current_user.github_token, project_info['name'])
    if s3_infos['filename'] && s3_infos['s3_url']
      delete_project_from_s3( project.s3_filename )
      project.s3_filename = s3_infos['filename']
      project.url = s3_infos['s3_url']
      project.save
    end
  end
  
  def self.create_from_file(project_type, url)
    project = nil
    if project_type.eql?("Maven2")
      project = Project.create_from_pom_url ( url )
    elsif project_type.eql?("RubyGems")
      project = Project.create_from_gemfile_url ( url )
    elsif project_type.eql?("PIP")
      project = Project.create_from_pip_url ( url )
    elsif project_type.eql?("npm")
      project = Project.create_from_npm_url ( url )
    end
    project
  rescue => e 
    p "exception: #{e}"
  end
  
  def self.create_from_pom_url( url )
    return nil if url.nil?
    url = do_replacements_for_github( url )
    doc = Nokogiri::XML( open( url ) )
    doc.remove_namespaces!
    return nil if doc.nil?
      
    project = Project.new
    project.dependencies = Array.new
    
    properties = Hash.new
    doc.xpath('//project/properties').each do |node|
      node.children.each do |child|
        if !child.text.strip.empty?
          properties[child.name.downcase] = child.text.strip
        end
      end  
    end
    
    doc.xpath('//project/dependencies/dependency').each do |node|
      project.dependencies << fetch_dependency(node, properties, project)
    end
    doc.xpath('//project/dependencyManagement/dependencies/dependency').each do |node|
      project.dependencies << fetch_dependency(node, properties, project)
    end
    
    project.dep_number = project.dependencies.count
    project
  end
  
  def self.create_from_pip_url( url )
    return nil if url.nil?
    url = do_replacements_for_github( url )
    uri = URI(url)
    txt = Net::HTTP.get(uri)
    return nil if txt.nil?
    
    project = Project.new
    project.dependencies = Array.new
    
    txt.each_line do |line|

      if !line.match(/^#/).nil?
        next
      end

      splitter = "=="
      if !line.match(/>=/).nil?
        splitter = ">="
      elsif !line.match(/>/).nil?
        splitter = ">"  
      end
      requirement = line.split(splitter)
      
      if requirement.empty? || requirement.count != 2
        next
      end
      
      package = requirement[0]
      
      if package.strip.empty? 
        next
      end
      
      dependency = Projectdependency.new
      dependency.name = package
      dependency.comperator = splitter
      dependency.scope = "compile"
      
      version = requirement[1]
      dependency.version = version.strip
      
      product = Product.find_by_key("pip/#{package}")
      if product.nil? 
        product = Product.find_by_key_case_insensitiv("pip/#{package}")
      end
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
    url = do_replacements_for_github( url )
    uri = URI.parse( url )
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.port == 443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end        
    request = Net::HTTP::Get.new(uri.request_uri)
    gemfile = http.request(request).body
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
      line_elements = line.split(",")
      package = line_elements[0].strip
      package = package.gsub('"', '')
      package = package.gsub("'", "")
      
      dependency = Projectdependency.new
      dependency.name = package
      
      product = Product.find_by_key(package)
      if !product.nil?
        dependency.prod_key = product.prod_key
      end
      
      update_version_from_file(line_elements[1], dependency, product)
      
      dependency.update_outdated
      if dependency.outdated?
        project.out_number = project.out_number + 1
      end      
      project.dependencies << dependency
    end
    project.dep_number = project.dependencies.count
    project
  end

  def self.create_from_npm_url ( url )
    return nil if url.nil?
    resp = Net::HTTP.get_response(URI.parse(url))
    data = JSON.parse( resp.body )
    dependencies = data['dependencies']
    return nil if dependencies.nil?

    project = Project.new
    project.dependencies = Array.new    

    dependencies.each do |key, value|
      dependency = Projectdependency.new
      dependency.name = key
      
      product = Product.find_by_key("npm/#{key}")
      if product
        dependency.prod_key = product.prod_key
      end
      
      update_version_from_file(value, dependency, product)
      
      dependency.update_outdated
      if dependency.outdated?
        project.out_number = project.out_number + 1
      end      
      project.dependencies << dependency
    end

    project.dep_number = project.dependencies.count
    project
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
  
  def self.update_version_from_file(version, dependency, product)
    if (version.nil?)
      update_dep_version_with_product(dependency, product)
      return 
    end
    version = version.strip
    version = version.gsub('"', '')
    version = version.gsub("'", "")
    if version.match(/^http/)
      dependency.version = "UNKNOWN"
    elsif version.match(/^:require/)
      update_dep_version_with_product(dependency, product)
    elsif version.match(/^\*/)
      update_dep_version_with_product(dependency, product)
      dependency.version_label = "*"
      dependency.comperator = "="
    elsif version.match(/.x$/) || version.match(/.X$/)
      dependency.version_label = version
      dependency.version = version.gsub(".x", ".0")
      dependency.version = dependency.version.gsub(".X", ".0")
      dependency.comperator = "~"
    elsif version.match(/^>/)
      update_dep_version_with_product(dependency, product)
      dependency.comperator = ">"
    elsif version.match(/^>=/)
      update_dep_version_with_product(dependency, product)
      dependency.comperator = ">="
    elsif version.match(/^~>/)
      ver = version.gsub("~>", "")
      ver = ver.gsub(" ", "")
      dependency.version = ver
      dependency.comperator = "~>"
    elsif version.match(/^~/)
      ver = version.gsub("~", "")
      ver = ver.gsub(" ", "")
      dependency.version = ver
      dependency.comperator = "~"
    else
      dependency.version = version
      dependency.comperator = "="
    end
  end

  def self.sanitize_filename(file_name)
    just_filename = File.basename(file_name)
    just_filename.sub(/[^\w\.\-]/,'_')
  end

  def self.upload_to_s3( fileUp )
    orig_filename =  fileUp['datafile'].original_filename
    fname = Project.sanitize_filename(orig_filename)
    random = Project.create_random_value
    filename = "#{random}_#{fname}"
    AWS::S3::S3Object.store(filename, 
      fileUp['datafile'].read, 
      Settings.s3_projects_bucket, 
      :access => "private")
    filename
  end

  def self.get_project_url_from_s3 filename
    AWS::S3::S3Object.url_for(filename, Settings.s3_projects_bucket, :authenticated => true)
  end

  def self.delete_project_from_s3 filename
    AWS::S3::S3Object.delete filename, Settings.s3_projects_bucket
  end

  def self.get_repo_sha_from_github(git_project, token)
    heads = JSON.parse HTTParty.get("https://api.github.com/repos/#{git_project}/git/refs/heads?access_token=" + URI.escape(token) ).response.body
    heads[0]['object']['sha']
  end

  def self.get_project_info_from_github(git_project, sha, token)
    result = Hash.new
    tree = JSON.parse HTTParty.get("https://api.github.com/repos/#{git_project}/git/trees/#{sha}?access_token=" + URI.escape(token) ).response.body
    tree['tree'].each do |file|
      name = file['path']
      if name.eql?("Gemfile")
        result['url'] = file['url']
        result['name'] = name
        result['type'] = "RubyGems"
      elsif name.eql?("pom.xml")
        result['url'] = file['url']
        result['name'] = name
        result['type'] = "Maven2"
      elsif name.eql?("requirements.txt")
        result['url'] = file['url']
        result['name'] = name
        result['type'] = "PIP"
      elsif name.eql?("package.json")
        result['url'] = file['url']
        result['name'] = name
        result['type'] = "npm"
      end 
    end
    result
  end

  def self.fetch_file_from_github(url, token, filename)
    file = JSON.parse HTTParty.get( "#{url}?access_token=" + URI.escape(token) ).response.body
    file_bin = file['content']
    random_value = Project.create_random_value
    new_filename = "#{random_value}_#{filename}"
    AWS::S3::S3Object.store(
      new_filename, 
      Base64.decode64(file_bin), 
      Settings.s3_projects_bucket,
      :access => "private")
    url = Project.get_project_url_from_s3(new_filename)
    result = Hash.new
    result['filename'] = new_filename
    result['s3_url'] = url
    result
  end

  def self.create_random_value
    chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    value = ""
    20.times { value << chars[rand(chars.size)] }
    value
  end
  
  private 
  
    def self.update_dep_version_with_product( dependency, product )
      if product && product.version
        dependency.version = product.version
      else
        dependency.version = "UNKNOWN"
      end
      dependency
    end

    def self.fetch_dependency(node, properties, project)
      dependency = Projectdependency.new
      node.children.each do |child|  
        if child.name.casecmp("groupId") == 0
          dependency.group_id = child.text.strip 
        elsif child.name.casecmp("artifactId") == 0
          dependency.artifact_id = child.text.strip
        elsif child.name.casecmp("version") == 0
          dependency.version = Project.get_variable_value_from_pom(properties, child.text.strip)
        elsif child.name.casecmp("scope") == 0
          dependency.scope = child.text.strip
        end
      end
      dependency.name = dependency.artifact_id
      if dependency.scope.nil? 
        dependency.scope = "compile"
      end
      
      product = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id)
      if !product.nil?
        dependency.prod_key = product.prod_key
      end
      
      dependency.update_outdated
      if dependency.outdated?
        project.out_number = project.out_number + 1
      end
      dependency
    end

    def self.do_replacements_for_github(url)
      if url.match(/^https:\/\/github.com\//)
        url = url.gsub("https://github.com", "https://raw.github.com")
        url = url.gsub("/blob/", "/")
      end
      url
    end
  
end