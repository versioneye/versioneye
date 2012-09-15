class PomParser
  
    # Parser for pom.xml file from Maven2/Maven3. Java.
    # XPath: //project/dependencyManagement/dependencies/dependency
    # XPath: //project/dependencies/dependency
    # 
    def self.parse( url )
      return nil if url.nil?
      
      response = CommonParser.fetch_response(url)
      doc = Nokogiri::XML( response.body )
      return nil if doc.nil?

      doc.remove_namespaces!
      return nil if doc.nil?

      project = Project.new
      project.dependencies = Array.new

      properties = fetch_properties( doc )

      doc.xpath('//dependencies/dependency').each do |node|
        dep = fetch_dependency(node, properties, project)
        project.dependencies.push( dep )
      end

      project.dep_number = project.dependencies.count
      project
    end
    
    def self.fetch_dependency(node, properties, project)
      dependency = Projectdependency.new
      node.children.each do |child|  
        if child.name.casecmp("groupId") == 0
          dependency.group_id = child.text.strip 
        elsif child.name.casecmp("artifactId") == 0
          dependency.artifact_id = child.text.strip
        elsif child.name.casecmp("version") == 0
          version_text = PomParser.get_variable_value_from_pom(properties, child.text.strip)
          dependency.version_requested = version_text
        elsif child.name.casecmp("scope") == 0
          dependency.scope = child.text.strip
        end
      end
      dependency.name = dependency.artifact_id
      if dependency.scope.nil? 
        dependency.scope = "compile"
      end
      
      product = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id)
      if product
        dependency.prod_key = product.prod_key
        if dependency.version_requested.nil? 
          dependency.version_requested = product.version
        end
      end
      
      dependency.update_outdated
      if dependency.outdated?
        project.out_number = project.out_number + 1
      end
      dependency
    end

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