class ComposerParser
  
  # Parser for composer.json files from composer, packagist.org. PHP
  # http://getcomposer.org/doc/01-basic-usage.md
  #
  def self.parse ( url )
    return nil if url.nil? 
    
    response = CommonParser.fetch_response(url)
    data = JSON.parse( response.body )
    return nil if data.nil?

    dependencies = fetch_dependencies data
    return nil if dependencies.nil?

    project = Project.new
    project.dependencies = Array.new    

    dependencies.each do |key, value|
      dependency = Projectdependency.new
      dependency.name = key
      
      product = Product.find_by_key("php/#{key}")
      if product.nil? 
        product = Product.find_by_key_case_insensitiv("php/#{key}")
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

    name = data['name']
    description = data['description']
    license = data['license']
    project.name = name if name
    project.description = description if description
    project.license = license if license
    project.dep_number = project.dependencies.count
    project
  rescue => e 
    p "#{e}"
    e.backtrace.each do |message|
      p " - #{message}"
    end
    nil
  end

  # It is important that this method is not writing into the database! 
  # 
  # TODO Write tests for this
  #
  def self.parse_requested_version(version, dependency, product)
    if (version.nil? || version.empty?)
      CommonParser.update_requested_with_current(dependency, product)
      return 
    end
    version = version.strip
    version = version.gsub('"', '')
    version = version.gsub("'", "")
    
    if product.nil? 
      dependency.version_requested = version
      dependency.version_label = version

    elsif version.match(/,/)
      # Version Ranges
      version_splitted = version.split(",")
      prod = Product.new 
      prod.versions = product.versions 
      version_splitted.each do |verso|
        verso.gsub!(" ", "")
        if verso.match(/^>=/)
          verso.gsub!(">=", "")  
          new_range = prod.get_greater_than_or_equal( verso, true )
          prod.versions = new_range
        elsif verso.match(/^>/)
          verso.gsub!(">", "")
          new_range = prod.get_greater_than( verso, true )
          prod.versions = new_range
        elsif verso.match(/^<=/)
          verso.gsub!("<=", "")
          new_range = prod.get_smaller_than_or_equal( verso, true )
          prod.versions = new_range
        elsif verso.match(/^</)
          verso.gsub!("<", "")
          new_range = prod.get_smaller_than( verso, true )
          prod.versions = new_range
        elsif verso.match(/^!=/)
          verso.gsub!("!=", "")
          new_range = prod.get_newest_but_not(verso, true)
          prod.versions = new_range
        end
      end
      highest_version = Product.get_newest_version_by_natural_order( prod.versions )
      if highest_version
        dependency.version_requested = highest_version.version
      else 
        dependency.version_requested = version
      end
      dependency.comperator = "="
      dependency.version_label = version
    
    elsif version.match(/.\*$/)
      # WildCards. 1.0.* => 1.0.0 | 1.0.2 | 1.0.20
      ver = version.gsub("*", "")
      ver = ver.gsub(" ", "")
      versions = product.get_versions_start_with(ver)
      highest_version = Product.get_newest_version_by_natural_order(versions)
      if highest_version
        dependency.version_requested = highest_version.version
      else 
        dependency.version_requested = version
      end
      dependency.comperator = "="
      dependency.version_label = version

    elsif version.empty? || version.match(/^\*$/)
      # This case is not allowed. But we handle it anyway. Because we are fucking awesome!
      dependency.version_requested = product.version
      dependency.version_label = "*"
      dependency.comperator = "="
    
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
    
    elsif version.match(/^!=/)
      # Not equal to version
      version.gsub!("!=", "")
      version.gsub!(" ", "")
      newest_version = product.get_newest_but_not(version)
      dependency.version_requested = newest_version.version
      dependency.comperator = "!="
      dependency.version_label = version
    
    else # = 
      dependency.version_requested = version
      dependency.comperator = "="
      dependency.version_label = version
    end

  end

  def self.fetch_dependencies data
    dependencies     = data['require']
    dependencies_dev = data['require-dev']
    if dependencies && dependencies_dev.nil?
      return dependencies
    elsif dependencies.nil? && dependencies_dev
      return dependencies_dev
    elsif dependencies && dependencies_dev 
      return dependencies.merge(dependencies_dev)
    end
    return nil
  end

end
