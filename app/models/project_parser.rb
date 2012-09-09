class ProjectParser

  def self.create_from_pom_url( url )
    return nil if url.nil?
    url = do_replacements_for_github( url )
    doc = Nokogiri::XML( open( url ) )
    doc.remove_namespaces!
    return nil if doc.nil?
      
    project = Project.new
    project.dependencies = Array.new
    
    properties = fetch_properties( doc )
    
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

  private 

  	def self.fetch_properties( doc )
      properties = Hash.new
      doc.xpath('//project/properties').each do |node|
        node.children.each do |child|
          if !child.text.strip.empty?
            properties[child.name.downcase] = child.text.strip
          end
        end  
      end
      project_version = doc.xpath('//project/version')
      if project_version
        properties['project.version'] = project_version.text.strip
      end
      properties
    end

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
          dependency.version = ProjectParser.get_variable_value_from_pom(properties, child.text.strip)
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
        if dependency.version.nil? 
          dependency.version = product.version
        end
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