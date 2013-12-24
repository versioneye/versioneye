class PackageParser < CommonParser

  # Parser for requirements.json from npm. NodeJS
  # https://npmjs.org/doc/json.html
  # http://wiki.commonjs.org/wiki/Packages/1.1
  #
  def parse ( url )
    return nil if url.to_s.empty?

    data = self.fetch_response_body_json( url )
    return nil if data.nil?

    dependencies = fetch_dependencies( data )
    return nil if dependencies.nil?

    project = init_project( url, data )
    dependencies.each do |key, value|
      parse_line( key, value, project )
    end
    project.dep_number = project.dependencies.size
    project
  end

  def parse_line( key, value, project )
    product    = Product.fetch_product( Product::A_LANGUAGE_NODEJS, key )
    dependency = init_dependency( product, key )
    parse_requested_version( value, dependency, product )
    project.out_number     += 1 if dependency.outdated?
    project.unknown_number += 1 if product.nil?
    project.projectdependencies.push dependency
  end

  # It is important that this method is not writing int the database!
  #
  def parse_requested_version(version, dependency, product)
    if version.to_s.strip.empty?
      self.update_requested_with_current(dependency, product)
      return
    end
    version = version.to_s.strip
    version = version.gsub('"', '')
    version = version.gsub("'", '')

    if product.nil?
      dependency.version_requested = version
      dependency.version_label     = version
      return
    end

    if version.match(/\*/)
      # Start Matching. Matches everything.
      dependency.version_requested = product.version
      dependency.version_label = '*'
      dependency.comperator = '='

    elsif version.casecmp('latest') == 0
      # Start Matching. Matches everything.
      dependency.version_requested = product.version
      dependency.version_label = 'latest'
      dependency.comperator = '='

    elsif version.match(/^=/)
      # Equals
      version.gsub!('=', '')
      version.gsub!(' ', '')
      dependency.version_requested = version
      dependency.version_label = version
      dependency.comperator = '='

    elsif version.match(/^!=/)
      # Not equal to version
      version.gsub!('!=', '')
      version.gsub!(' ', '')
      newest_version = VersionService.newest_but_not(product.versions, version)
      dependency.version_requested = newest_version
      dependency.comperator = '!='
      dependency.version_label = version

    elsif version.match(/^>=/)
      # Greater than or equal to
      version.gsub!('>=', '')
      version.gsub!(' ', '')
      newest_version = VersionService.greater_than_or_equal(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = '>='
      dependency.version_label = version

    elsif version.match(/^>/)
      # Greater than version
      version.gsub!('>', '')
      version.gsub!(' ', '')
      newest_version = VersionService.greater_than(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = ">"
      dependency.version_label = version

    elsif version.match(/^<=/)
      # Less than or equal to
      version.gsub!("<=", "")
      version.gsub!(" ", "")
      newest_version = VersionService.smaller_than_or_equal(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = "<="
      dependency.version_label = version

    elsif version.match(/^\</)
      # Less than version
      version.gsub!("\<", "")
      version.gsub!(" ", "")
      newest_version = VersionService.smaller_than(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = "<"
      dependency.version_label = version

    elsif version.match(/^~/)
      # Tilde Version Ranges -> Pessimistic Version Constraint
      # ~1.2.3 = >=1.2.3 <1.3.0
      ver = version.gsub("\>", "")
      ver = ver.gsub("~", "")
      ver = ver.gsub(" ", "")
      highest_version = VersionService.version_tilde_newest(product.versions, ver)
      if highest_version
        dependency.version_requested = highest_version.to_s
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
      versions        = VersionService.versions_start_with( product.versions, ver )
      highest_version = VersionService.newest_version_from(versions)
      if highest_version
        dependency.version_requested = highest_version.to_s
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
      version_range   = VersionService.version_range(product.versions, start, stop)
      highest_version = VersionService.newest_version_from( version_range )
      if highest_version
        dependency.version_requested = highest_version.to_s
      else
        dependency.version_requested = version
      end
      dependency.comperator    = "="
      dependency.version_label = version

    else
      dependency.version_requested = version
      dependency.comperator        = "="
      dependency.version_label     = version
    end
  end

  def init_project( url, data )
    project = Project.new
    project.project_type = Project::A_TYPE_NPM
    project.language     = Product::A_LANGUAGE_NODEJS
    project.url          = url
    project.name         = data['name']
    project.description  = data['description']
    project
  end

  def fetch_dependencies( data )
    dependencies = data['dependencies']
    dev_dependencies = data['devDependencies']
    if dev_dependencies
      if dependencies.nil?
        dependencies = dev_dependencies
      else
        dependencies.merge!(dev_dependencies)
      end
    end
    dependencies
  end

  def init_dependency( product, name )
    dependency          = Projectdependency.new
    dependency.name     = name
    dependency.language = Product::A_LANGUAGE_NODEJS
    if product
      dependency.prod_key        = product.prod_key
      dependency.version_current = product.version
    end
    dependency
  end

end
