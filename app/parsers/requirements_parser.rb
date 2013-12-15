class RequirementsParser < CommonParser

  # Parser for requirements.txt files from pip. Python.
  # http://www.pip-installer.org/en/latest/requirements.html#the-requirements-file-format
  # http://www.pip-installer.org/en/latest/#requirements-files
  #
  def parse( url )
    return nil if url.nil?

    response = self.fetch_response(url)
    txt = response.body
    return nil if txt.nil? || txt.empty?

    project = init_project( url )

    txt.each_line do |line|
      parse_line line, project
    end

    project.dep_number = project.dependencies.size

    return project
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  end


  def parse_line( line, project )
    line.gsub!(" ", "")
    return false if !line.match(/^#/).nil? || line.empty?

    comparator  = extract_comparator line
    requirement = line.split(comparator)
    package = requirement[0]

    return false if package.nil? || package.strip.empty?
    return false if package.match(/^http:\/\//)
    return false if package.match(/^https:\/\//)
    return false if package.match(/^--/)

    dependency = init_dependency package, comparator

    version = ''
    if requirement.count > 1
      version = requirement[1]
      dependency.version_label = version.strip
    end

    product = Product.fetch_product Product::A_LANGUAGE_PYTHON, package
    if product
      dependency.prod_key = product.prod_key
    else
      project.unknown_number = project.unknown_number + 1
    end

    parse_requested_version("#{comparator}#{version}", dependency, product)

    if dependency.outdated?
      project.out_number = project.out_number + 1
    end
    project.projectdependencies.push dependency
  end


  # It is important that this method is not writing int the database!
  #
  def parse_requested_version(version, dependency, product)
    if version.nil? || version.empty?
      self.update_requested_with_current(dependency, product)
      return
    end
    version = version.strip
    version = version.gsub('"', '')
    version = version.gsub("'", "")
    dependency.version_label = String.new(version)

    if product.nil?
      dependency.version_requested = version
      return nil
    end

    if version.match(/,/)
      # Version Ranges
      version_splitted = version.split(",")
      prod = Product.new
      prod.versions = product.versions
      version_splitted.each do |verso|
        verso.gsub!(" ", "")
        if verso.match(/^>=/)
          verso.gsub!(">=", "")
          new_range = VersionService.greater_than_or_equal( product.versions, verso, true )
          prod.versions = new_range
        elsif verso.match(/^>/)
          verso.gsub!(">", "")
          new_range = VersionService.greater_than( product.versions, verso, true )
          prod.versions = new_range
        elsif verso.match(/^<=/)
          verso.gsub!("<=", "")
          new_range = VersionService.smaller_than_or_equal( product.versions, verso, true )
          prod.versions = new_range
        elsif verso.match(/^</)
          verso.gsub!("<", "")
          new_range = VersionService.smaller_than( product.versions, verso, true )
          prod.versions = new_range
        elsif verso.match(/^!=/)
          verso.gsub!("!=", "")
          new_range = VersionService.newest_but_not( product.versions, verso, true)
          prod.versions = new_range
        end
      end
      highest_version = VersionService.newest_version_from( prod.versions )
      if highest_version
        dependency.version_requested = highest_version.to_s
      else
        dependency.version_requested = version
      end
      dependency.comperator = "="


    elsif version.match(/.\*$/)
      # WildCards. 1.0.* => 1.0.0 | 1.0.2 | 1.0.20
      ver = version.gsub("*", "")
      ver = ver.gsub(" ", "")
      highest_version = VersionService.newest_version_from_wildcard( product.versions, ver, dependency.stability )
      if highest_version
        dependency.version_requested = highest_version
      else
        dependency.version_requested = version
      end
      dependency.comperator = "="

    elsif version.empty? || version.match(/^\*$/)
      # This case is not allowed. But we handle it anyway. Because we are fucking awesome!
      dependency.version_requested = VersionService.newest_version_number( product.versions, dependency.stability )
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
      newest_version = VersionService.newest_but_not(product.versions, version)
      dependency.version_requested = newest_version
      dependency.comperator = "!="

    elsif version.match(/^>=/)
      # Greater than or equal to
      version.gsub!(">=", "")
      version.gsub!(" ", "")
      newest_version = VersionService.greater_than_or_equal(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = ">="

    elsif version.match(/^>/)
      # Greater than version
      version.gsub!(">", "")
      version.gsub!(" ", "")
      newest_version = VersionService.greater_than(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = ">"

    elsif version.match(/^<=/)
      # Less than or equal to
      version.gsub!("<=", "")
      version.gsub!(" ", "")
      newest_version = VersionService.smaller_than_or_equal(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = "<="

    elsif version.match(/^\</)
      # Less than version
      version.gsub!("<", "")
      version.gsub!(" ", "")
      newest_version = VersionService.smaller_than(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = "<"

    else
      dependency.version_requested = version
      dependency.comperator = "=="
    end

  end


  def init_project url
    project              = Project.new
    project.project_type = Project::A_TYPE_PIP
    project.language     = Product::A_LANGUAGE_PYTHON
    project.url          = url
    project
  end


  def init_dependency package, comparator
    dependency = Projectdependency.new
    dependency.name = package
    dependency.comperator = comparator
    dependency.scope = Dependency::A_SCOPE_COMPILE
    dependency.language = Product::A_LANGUAGE_PYTHON
    dependency
  end


  def extract_comparator line
    comparator = nil
    if line.match(/>=/)
      comparator = ">="
    elsif line.match(/>/)
      comparator = ">"
    elsif line.match(/<=/)
      comparator = "<="
    elsif line.match(/</)
      comparator = "<"
    elsif line.match(/!=/)
      comparator = "!="
    elsif line.match(/==/)
      comparator = "=="
    end
    comparator
  end

end
