class PackageParser < CommonParser
  
  # Parser for requirements.json from npm. NodeJS
  # https://npmjs.org/doc/json.html
  # http://wiki.commonjs.org/wiki/Packages/1.1
  # 
  def parse ( url )
    return nil if url.nil?
    
    response = self.fetch_response(url)
    data = JSON.parse( response.body )
    return nil if data.nil?

    dependencies = data['dependencies']
    return nil if dependencies.nil?

    dev_dependencies = data['devDependencies']
    if dev_dependencies 
      dependencies.merge!(dev_dependencies)
    end

    project = Project.new
    project.dependencies = Array.new    

    project.name = data['name']
    project.description = data['description']

    dependencies.each do |key, value|
      dependency = Projectdependency.new
      dependency.name = key
      
      key = "npm/#{key}"
      product = Product.find_by_key(key)
      if product.nil? 
        product = Product.find_by_key_case_insensitiv(key)
      end
      if product
        dependency.prod_key = product.prod_key
      else 
        project.unknown_number = project.unknown_number + 1
      end
      
      parse_requested_version(value, dependency, product)
      
      dependency.update_outdated
      if dependency.outdated?
        project.out_number = project.out_number + 1
      end      
      project.dependencies << dependency
    end

    project.dep_number = project.dependencies.count
    project.project_type = Project::A_TYPE_NPM
    project.language = Product::A_LANGUAGE_NODEJS
    project.url = url
    project
  end

  # It is important that this method is not writing int the database! 
  #
  def parse_requested_version(version, dependency, product)
    if (version.nil? || version.empty?)
      self.update_requested_with_current(dependency, product)
      return 
    end
    version = version.strip
    version = version.gsub('"', '')
    version = version.gsub("'", "")
    
    if product.nil? 
      dependency.version_requested = version
      dependency.version_label = version
    
    elsif version.match(/\*/) || version.empty?
      # Start Matching. Matches everything.
      dependency.version_requested = product.version
      dependency.version_label = "*"
      dependency.comperator = "="
    
    elsif version.match(/^=/)
      # Equals
      version.gsub!("=", "")
      version.gsub!(" ", "")
      dependency.version_requested = version
      dependency.version_label = version
      dependency.comperator = "="
    
    elsif version.match(/^!=/)
      # Not equal to version
      version.gsub!("!=", "")
      version.gsub!(" ", "")
      newest_version = product.get_newest_but_not(version)
      dependency.version_requested = newest_version
      dependency.comperator = "!="
      dependency.version_label = version
    
    elsif version.match(/^>=/)
      # Greater than or equal to
      version.gsub!(">=", "")
      version.gsub!(" ", "")
      newest_version = product.get_greater_than_or_equal(version)
      dependency.version_requested = newest_version.version
      dependency.comperator = ">="
      dependency.version_label = version
    
    elsif version.match(/^>/)
      # Greater than version
      version.gsub!(">", "")
      version.gsub!(" ", "")
      newest_version = product.get_greater_than(version)
      dependency.version_requested = newest_version.version
      dependency.comperator = ">"
      dependency.version_label = version
    
    elsif version.match(/^<=/)
      # Less than or equal to
      version.gsub!("<=", "")
      version.gsub!(" ", "")
      newest_version = product.get_smaller_than_or_equal(version)
      dependency.version_requested = newest_version.version
      dependency.comperator = "<="
      dependency.version_label = version
    
    elsif version.match(/^\</)
      # Less than version
      version.gsub!("\<", "")
      version.gsub!(" ", "")
      newest_version = product.get_smaller_than(version)
      dependency.version_requested = newest_version.version
      dependency.comperator = "<"
      dependency.version_label = version
    
    elsif version.match(/^~/)
      # Tilde Version Ranges -> Pessimistic Version Constraint
      # ~1.2.3 = >=1.2.3 <1.3.0
      ver = version.gsub("~", "")
      ver = ver.gsub(" ", "")
      highest_version = product.get_tilde_newest(ver)
      if highest_version
        dependency.version_requested = highest_version.version
      else 
        dependency.version_requested = ver
      end
      dependency.comperator = "~"
      dependency.version_label = ver
    
    elsif version.match(/.x$/i)
      # X Version Ranges
      ver = version.gsub("x", "")
      ver = ver.gsub("X", "")
      ver = ver.gsub(" ", "")
      versions = product.get_versions_start_with(ver)
      highest_version = Product.newest_version_from(versions)
      if highest_version
        dependency.version_requested = highest_version.version
      else 
        dependency.version_requested = version
      end
      dependency.comperator = "="
      dependency.version_label = version
    
    elsif version.match(/ - /i)
      # Version Ranges
      version_splitted = version.split(" - ")
      start = version_splitted[0]
      stop = version_splitted[1]
      version_range = product.get_version_range(start, stop)
      highest_version = Product.newest_version_from( version_range )
      if highest_version
        dependency.version_requested = highest_version.version
      else 
        dependency.version_requested = version
      end
      dependency.comperator = "="
      dependency.version_label = version
    
    else
      dependency.version_requested = version
      dependency.comperator = "="
      dependency.version_label = version
    end
    
  end
  
end
