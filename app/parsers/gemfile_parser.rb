class GemfileParser < CommonParser

  # Parser for Gemfile. For Ruby.
  # http://gembundler.com/man/gemfile.5.html
  # http://guides.rubygems.org/patterns/#semantic_versioning
  #
  def parse ( url )
    return nil if url.nil? || url.empty?
    gemfile = fetch_response_body( url )
    return nil if gemfile.nil?
    project = init_project( url )
    gemfile.each_line do |line|
      parse_line( line, project )
    end
    project.dep_number = project.dependencies.size
    project
  end

  def parse_line( line, project )
    line_elements = fetch_line_elements( line )
    gem_name      = fetch_gem_name( line_elements )

    return nil if gem_name.nil?

    version    = fetch_version  ( line_elements )
    product    = Product.fetch_product Product::A_LANGUAGE_RUBY, gem_name
    dependency = init_dependency( product, gem_name )

    parse_requested_version( version, dependency, product )

    project.projectdependencies.push dependency
    project.out_number     += 1 if dependency.outdated?
    project.unknown_number += 1 if product.nil?
  end

  # It is important that this method is not writing into the database!
  def parse_requested_version(version_number, dependency, product)
    if version_number.nil? || version_number.empty?
      self.update_requested_with_current(dependency, product)
      return
    end

    if product.nil?
      dependency.version_requested = version_number
      dependency.version_label     = version_number
      return
    end

    version = String.new( version_number )

    if version.match(/^=/)
      # Equals
      version.gsub!('=', '')
      version.gsub!(' ', '')
      dependency.version_requested = version
      dependency.version_label     = version
      dependency.comperator        = '='

    elsif version.match(/^!=/)
      # Not equal to version
      version.gsub!('!=', '')
      version.gsub!(' ', '')
      newest_version = VersionService.newest_but_not( product.versions, version)
      dependency.version_requested = newest_version
      dependency.comperator        = '!='
      dependency.version_label     = version

    elsif version.match(/^>=/)
      # Greater than or equal to
      version.gsub!('>=', '')
      version.gsub!(' ', '')
      newest_version = VersionService.greater_than_or_equal( product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator        = '>='
      dependency.version_label     = version

    elsif version.match(/^>/)
      # Greater than version
      version.gsub!('>', '')
      version.gsub!(' ', '')
      newest_version = VersionService.greater_than( product.versions, version )
      dependency.version_requested = newest_version.to_s
      dependency.comperator        = ">"
      dependency.version_label     = version

    elsif version.match(/^<=/)
      # Less than or equal to
      version.gsub!("<=", "")
      version.gsub!(" ", "")
      newest_version = VersionService.smaller_than_or_equal( product.versions, version )
      dependency.version_requested = newest_version.to_s
      dependency.comperator        = "<="
      dependency.version_label     = version

    elsif version.match(/^\</)
      # Less than version
      version.gsub!("\<", "")
      version.gsub!(" ", "")
      newest_version = VersionService.smaller_than( product.versions, version )
      dependency.version_requested = newest_version.to_s
      dependency.comperator        = "<"
      dependency.version_label     = version

    elsif version.match(/^~>/)
      # Approximately greater than -> Pessimistic Version Constraint
      ver = version.gsub("~>", "")
      ver = ver.gsub(" ", "")
      starter         = VersionService.version_approximately_greater_than_starter( ver )
      versions        = VersionService.versions_start_with( product.versions, starter )
      highest_version = VersionService.newest_version_from( versions )
      if highest_version
        dependency.version_requested = highest_version.to_s
      else
        dependency.version_requested = ver
      end
      dependency.comperator = "~>"
      dependency.version_label = ver

    elsif version.match(/^git:/) or version.match(/^:git/)
      dependency.version_requested = "GIT"
      dependency.version_label     = "GIT"
      dependency.comperator        = "="

    elsif version.match(/^path:/) or version.match(/^:path/)
      dependency.version_requested = "PATH"
      dependency.version_label     = "PATH"
      dependency.comperator        = "="

    else
      dependency.version_requested = version
      dependency.comperator        = "="
      dependency.version_label     = version
    end
  end

  def fetch_line_elements( line )
    line = replace_comments( line )
    line = line.strip
    line.split(",")
  end

  def fetch_gem_name( line_elements )
    gem_name = line_elements.first
    return nil if gem_name.nil? || gem_name.empty?
    return nil if gem_name.match(/^gem /).nil? # TODO check git as well !
    gem_name.gsub!("gem ", "")
    gem_name = gem_name.strip
    gem_name = gem_name.gsub('"', '')
    gem_name = gem_name.gsub("'", "")
    gem_name.split(" ").first
  end

  def fetch_version( line_elements )
    version = ""
    line_elements.each_with_index do |element, index|
      next if index == 0
      element = element.strip
      if element.match(/^require:/) or element.match(/^:require/)
        next
      elsif element.match(/^:group/) or element.match(/^group:/)
        next
      elsif element.match(/^:development/) or element.match(/^development:/)
        next
      elsif element.match(/^:test/) or element.match(/^test:/)
        next
      elsif element.match(/^:platforms/) or element.match(/^platforms:/)
        next
      elsif element.match(/^:engine/) or element.match(/^engine:/)
        next
      elsif element.match(/^:engine_version/) or element.match(/^engine_version:/)
        next
      elsif element.match(/^:branch/) or element.match(/^branch:/)
        next
      elsif element.match(/^:tag/) or element.match(/^tag:/)
        next
      elsif element.match(/^:path/) or element.match(/^path:/)
        version = element
        break
      elsif element.match(/^:git/) or element.match(/^git:/)
        version = element
        break
      else
        version = element
      end
    end
    version = version.gsub('"', '')
    version.gsub("'", "")
  end

  def replace_comments( value )
    return nil unless value
    comment = value.match(/#.*/)
    if comment
      value.gsub!(comment[0], "")
    end
    value
  end

  def init_project( url )
    project = Project.new
    project.project_type = Project::A_TYPE_RUBYGEMS
    project.language     = Product::A_LANGUAGE_RUBY
    project.url          = url
    project
  end

  def init_dependency( product, gem_name )
    dependency          = Projectdependency.new
    dependency.name     = gem_name
    dependency.language = Product::A_LANGUAGE_RUBY
    if product
      dependency.prod_key        = product.prod_key
      dependency.version_current = product.version
    end
    dependency
  end

end
