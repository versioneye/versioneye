class RequirementsParser
  
  # Parser for requirements.txt files from pip. Python.
  # http://www.pip-installer.org/en/latest/requirements.html#the-requirements-file-format
  # http://www.pip-installer.org/en/latest/#requirements-files
  #
  def self.parse( url )
    return nil if url.nil?
    
    response = CommonParser.fetch_response(url)
    txt = response.body
    return nil if txt.nil?
    
    project = Project.new
    project.dependencies = Array.new
    
    txt.each_line do |line|

      next if !line.match(/^#/).nil?

      splitter = RequirementsParser.get_splitter line
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
      end
      
      parse_requested_version(splitter, version, dependency, product)
      
      dependency.update_outdated
      if dependency.outdated?
        project.out_number = project.out_number + 1
      end      
      project.dependencies << dependency
    end
    project.dep_number = project.dependencies.count
    project
  rescue => e 
    print "#{e}"
    e.backtrace.each do |message|
      p "#{message}"
    end
  end

  # It is important that this method is not writing int the database! 
  #
  def self.parse_requested_version(splitter, version, dependency, product)
    if (version.nil? || version.empty?)
      CommonParser.update_requested_with_current(dependency, product)
      return 
    end
    version = version.strip
    version = version.gsub('"', '')
    version = version.gsub("'", "")
    dependency.version_label = version
    
    if product.nil? 
      dependency.version_requested = version
    
    elsif splitter.match(/^==/)
      # Equals
      dependency.version_requested = version
    
    elsif splitter.match(/^!=/)
      # Not equal to version
      newest_version = product.get_newest_but_not(version)
      dependency.version_requested = newest_version
    
    elsif splitter.match(/^>=/)
      # Greater than or equal to
      newest_version = product.get_greater_than_or_equal(version)
      dependency.version_requested = newest_version.version
    
    elsif splitter.match(/^>/)
      # Greater than version
      newest_version = product.get_greater_than(version)
      dependency.version_requested = newest_version.version
    
    elsif splitter.match(/^<=/)
      # Less than or equal to
      newest_version = product.get_smaller_than_or_equal(version)
      dependency.version_requested = newest_version.version
    
    elsif version.match(/^\</)
      # Less than version
      newest_version = product.get_smaller_than(version)
      dependency.version_requested = newest_version.version
    
    else
      dependency.version_requested = version
      dependency.comperator = "=="
    end
    
  end
  
  def self.get_splitter line
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