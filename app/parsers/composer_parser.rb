class ComposerParser < CommonParser
  
  # Parser for composer.json files from composer, packagist.org. PHP
  # http://getcomposer.org/doc/01-basic-usage.md
  #
  def parse ( url )
    data = self.fetch_data( url )
    return nil if data.nil?

    dependencies = fetch_dependencies data
    return nil if dependencies.nil?

    project = Project.new(:dependencies => Array.new)
    dependencies.each do |key, value|
      self.process_dependency( key, value, project, data )
    end
    self.update_project( project, data )
    project.project_type = Project::A_TYPE_COMPOSER
    project.language = Product::A_LANGUAGE_PHP
    project.url = url
    project
  rescue => e 
    print_backtrace e 
    nil
  end

  def fetch_data( url )
    return nil if url.nil? 
    response = self.fetch_response(url)
    JSON.parse( response.body )
  end

  def fetch_dependencies data
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

  def process_dependency( key, value, project, data )
    dependency = Projectdependency.new
    dependency.name = key
    
    product = self.product_by_key key
    dependency.prod_key = product.prod_key if product

    parse_requested_version( value, dependency, product )
    if product.nil?   
      dep_in_ext_repo = dependency_in_repositories?( dependency, data )
      project.unknown_number += 1 if !dep_in_ext_repo
    end 
    
    project.out_number += 1 if dependency.outdated?
    project.dependencies << dependency
  end

  def product_by_key( key )
    product = Product.find_by_key("php/#{key}")
    if product.nil? 
      product = Product.find_by_key_case_insensitiv("php/#{key}")
    end
    product
  end

  def update_project( project, data )
    name = data['name']
    description = data['description']
    license = data['license']
    project.name = name if name
    project.description = description if description
    project.license = license if license
    project.dep_number = project.dependencies.count
  end

  # It is important that this method is NOT writing into the database! 
  #
  def parse_requested_version(version, dependency, product)
    if (version.nil? || version.empty?) && !product.nil?
      update_requested_with_current(dependency, product)
      return 
    end
    version = version.strip
    version = version.gsub('"', '')
    version = version.gsub("'", "")

    dependency.version_label = String.new(version)
    
    dependency.stability = VersionTagRecognizer.stability_tag_for version 
    VersionTagRecognizer.remove_minimum_stability version
        
    if version.empty? && !product.nil?
      update_requested_with_current(dependency, product)
      return 
    end
    
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
    
    elsif version.match(/^>=/)
      # Greater than or equal to
      version.gsub!(">=", "")
      version.gsub!(" ", "")
      greater_than_or_equal = product.greater_than_or_equal(version)
      dependency.version_requested = greater_than_or_equal.version
      dependency.comperator = ">="
    
    elsif version.match(/^>/)
      # Greater than version
      version.gsub!(">", "")
      version.gsub!(" ", "")
      greater_than = product.greater_than(version)
      dependency.version_requested = greater_than.version
      dependency.comperator = ">"
    
    elsif version.match(/^<=/)
      # Less than or equal to
      version.gsub!("<=", "")
      version.gsub!(" ", "")
      smaller_or_equal = product.smaller_than_or_equal(version)
      dependency.version_requested = smaller_or_equal.version
      dependency.comperator = "<="
    
    elsif version.match(/^\</)
      # Less than version
      version.gsub!("\<", "")
      version.gsub!(" ", "")
      smaller_than = product.smaller_than(version)
      dependency.version_requested = smaller_than.version
      dependency.comperator = "<"
    
    elsif version.match(/^!=/)
      # Not equal to version
      version.gsub!("!=", "")
      version.gsub!(" ", "")
      newest_but_not = product.newest_but_not(version)
      dependency.version_requested = newest_but_not.version
      dependency.comperator = "!="
    
    else # = 
      dependency.version_requested = version
      dependency.comperator = "="
    end

  end

  # TODO write tests 
  # 
  def dependency_in_repositories?( dependency, data )
    return false if (dependency.nil? || data.nil?)
    repos = data['repositories']
    return false if (repos.nil? || repos.empty?)
    repos.each do |repo|
      repo_name = repo['package']['name']
      repo_version = repo['package']['version']
      repo_link = repo['package']['dist']['url']
      if repo_name.eql?(dependency.name)
        dependency.ext_link = repo_link
        dependency.version_current = repo_version
        return true 
      end
    end
    return false 
  rescue => e 
    print_backtrace( e )
    false 
  end

  private 

    # This method exist in CommonParser, too! 
    # This is just a copy with a different implementation for Composer! 
    #
    def update_requested_with_current( dependency, product )
      if product && product.version
        dependency.version_requested = product.newest_version_number( dependency.stability )
      else
        dependency.version_requested = "UNKNOWN"
      end
      dependency
    end

    def print_backtrace( e )
      p "#{e}"
      e.backtrace.each do |message|
        p " - #{message}"
      end
    end

end
