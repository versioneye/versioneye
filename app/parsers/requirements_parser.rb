class RequirementsParser < CommonParser
  
  # Parser for requirements.txt files from pip. Python.
  # http://www.pip-installer.org/en/latest/requirements.html#the-requirements-file-format
  # http://www.pip-installer.org/en/latest/#requirements-files
  #
  def parse( url )
    return nil if url.nil?
    
    response = self.fetch_response(url)
    txt = response.body
    return nil if txt.nil?
    
    project = Project.new
    project.dependencies = Array.new
    
    txt.each_line do |line|

      next if !line.match(/^#/).nil?

      splitter = get_splitter line
      requirement = line.split(splitter)
      
      next if requirement.empty? || requirement.count != 2
      
      package = requirement[0]
      
      next if package.strip.empty? 
      
      dependency = Projectdependency.new
      dependency.name = package
      dependency.comperator = splitter
      dependency.scope = "compile"
      
      version = requirement[1]
      dependency.version_label = version.strip
      
      key = "pip/#{package}"
      product = Product.find_by_key(key)
      if product.nil? 
        product = Product.find_by_key_case_insensitiv(key)
      end
      if product
        dependency.prod_key = product.prod_key
      else 
        project.unknown_number = project.unknown_number + 1
      end
      
      parse_requested_version("#{splitter}#{version}", dependency, product)
      
      if dependency.outdated?
        project.out_number = project.out_number + 1
      end
      project.dependencies << dependency
    end
    project.dep_number = project.dependencies.count
    project.project_type = Project::A_TYPE_PIP
    project.language = Product::A_LANGUAGE_PYTHON
    project.url = url
    project
  rescue => e 
    print "#{e}"
    e.backtrace.each do |message|
      p "#{message}"
    end
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
    dependency.version_label = String.new(version)
    
    if product.nil? 
      dependency.version_requested = version
 
    elsif version.match(/,/)
      # Version Ranges
      version_splitted = version.split(",")
      prod = Product.new 
      prod.versions = product.versions 
      version_splitted.each do |verso|
        verso.gsub!(" ", "")
        if verso.match(/^>=/)
          verso.gsub!(">=", "")  
          new_range = prod.greater_than_or_equal( verso, true )
          prod.versions = new_range
        elsif verso.match(/^>/)
          verso.gsub!(">", "")
          new_range = prod.greater_than( verso, true )
          prod.versions = new_range
        elsif verso.match(/^<=/)
          verso.gsub!("<=", "")
          new_range = prod.smaller_than_or_equal( verso, true )
          prod.versions = new_range
        elsif verso.match(/^</)
          verso.gsub!("<", "")
          new_range = prod.smaller_than( verso, true )
          prod.versions = new_range
        elsif verso.match(/^!=/)
          verso.gsub!("!=", "")
          new_range = prod.newest_but_not(verso, true)
          prod.versions = new_range
        end
      end
      highest_version = Product.newest_version_from( prod.versions )
      if highest_version
        dependency.version_requested = highest_version.version
      else 
        dependency.version_requested = version
      end
      dependency.comperator = "="
    
    
    elsif version.match(/.\*$/)
      # WildCards. 1.0.* => 1.0.0 | 1.0.2 | 1.0.20
      ver = version.gsub("*", "")
      ver = ver.gsub(" ", "")
      highest_version = product.newest_version_from_wildcard( ver, dependency.stability )
      if highest_version
        dependency.version_requested = highest_version
      else 
        dependency.version_requested = version
      end
      dependency.comperator = "="

    elsif version.empty? || version.match(/^\*$/)
      # This case is not allowed. But we handle it anyway. Because we are fucking awesome!
      dependency.version_requested = product.newest_version_number( dependency.stability )
      dependency.version_label = "*"
      dependency.comperator = "="
    
    elsif version.match(/^==/)
      # Equals
      version.gsub!("==", "")
      version.gsub!(" ", "")
      dependency.version_requested = version
      dependency.comperator = "=="
    
    elsif version.match(/^!=/)
      # Not equal to version
      version.gsub!("!=", "")
      version.gsub!(" ", "")
      newest_version = product.newest_but_not(version)
      dependency.version_requested = newest_version
      dependency.comperator = "!="
    
    elsif version.match(/^>=/)
      # Greater than or equal to
      version.gsub!(">=", "")
      version.gsub!(" ", "")
      newest_version = product.greater_than_or_equal(version)
      dependency.version_requested = newest_version.version
      dependency.comperator = ">="
    
    elsif version.match(/^>/)
      # Greater than version
      version.gsub!(">", "")
      version.gsub!(" ", "")
      newest_version = product.greater_than(version)
      dependency.version_requested = newest_version.version
      dependency.comperator = ">"
    
    elsif version.match(/^<=/)
      # Less than or equal to
      version.gsub!("<=", "")
      version.gsub!(" ", "")
      newest_version = product.smaller_than_or_equal(version)
      dependency.version_requested = newest_version.version
      dependency.comperator = "<="
    
    elsif version.match(/^\</)
      # Less than version
      version.gsub!("<", "")
      version.gsub!(" ", "")
      newest_version = product.smaller_than(version)
      dependency.version_requested = newest_version.version
      dependency.comperator = "<"
    
    else
      dependency.version_requested = version
      dependency.comperator = "=="
    end
    
  end
  
  def get_splitter line
    splitter = "=="
    if !line.match(/>=/).nil?
      splitter = ">="
    elsif !line.match(/>/).nil?
      splitter = ">"  
    elsif !line.match(/<=/).nil?
      splitter = "<="
    elsif !line.match(/</).nil?
      splitter = "<"
    end
    splitter
  end
  
end
