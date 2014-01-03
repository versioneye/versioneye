class ComposerParser < CommonParser

  # Parser for composer.json files from composer, packagist.org. PHP
  # http://getcomposer.org/doc/01-basic-usage.md
  # https://igor.io/2013/02/07/composer-stability-flags.html
  #
  def parse url
    data = self.fetch_data url
    return nil if data.nil?
    dependencies = fetch_dependencies data
    return nil if dependencies.nil?
    project = init_project( url )
    dependencies.each do |key, value|
      self.process_dependency( key, value, project, data )
    end
    self.update_project( project, data )
    project
  rescue => e
    print_backtrace e
    nil
  end

  def fetch_data url
    return nil if url.nil?
    response = self.fetch_response(url)
    return nil if response.nil?
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
    nil
  end

  def process_dependency key, value, project, data
    product    = Product.fetch_product( Product::A_LANGUAGE_PHP, key )
    dependency = init_projectdependency( key, product )
    parse_requested_version( value, dependency, product )
    if product.nil?
      dep_in_ext_repo = dependency_in_repositories?( dependency, data )
      project.unknown_number += 1 if !dep_in_ext_repo
    end
    project.out_number += 1 if dependency.outdated?
    project.projectdependencies.push dependency
  end

  def update_project project, data
    name                = data['name']
    description         = data['description']
    license             = data['license']
    project.name        = name if name
    project.description = description if description
    project.license     = license if license
    project.dep_number  = project.dependencies.size
  end

  # It is important that this method is NOT writing into the database!
  #
  def parse_requested_version version, dependency, product
    if (version.nil? || version.empty?) && !product.nil?
      update_requested_with_current(dependency, product)
      return
    end
    version = version.strip
    version = version.gsub('"', '')
    version = version.gsub("'", '')
    version = version.gsub(/^v/, '')

    dependency.version_label = String.new(version)

    dependency.stability = VersionTagRecognizer.stability_tag_for version
    VersionTagRecognizer.remove_minimum_stability version

    if version.empty? && !product.nil?
      update_requested_with_current(dependency, product)
      return
    end

    if product.nil?
      dependency.version_requested = version
      return nil
    end

    case
    when version.match(/,/)
      # Version Ranges
      version_splitted = version.split(",")
      prod = Product.new
      prod.versions = product.versions
      stability = dependency.stability
      version_splitted.each do |verso|
        verso.gsub!(" ", "")
        stability = VersionTagRecognizer.stability_tag_for verso
        if verso.match(/^>=/)
          verso.gsub!(">=", "")
          new_range = VersionService.greater_than_or_equal( prod.versions, verso, true, stability )
          prod.versions = new_range
        elsif verso.match(/^>/)
          verso.gsub!(">", "")
          new_range = VersionService.greater_than( prod.versions, verso, true, stability )
          prod.versions = new_range
        elsif verso.match(/^<=/)
          verso.gsub!("<=", "")
          new_range = VersionService.smaller_than_or_equal( prod.versions, verso, true, stability )
          prod.versions = new_range
        elsif verso.match(/^</)
          verso.gsub!("<", "")
          new_range = VersionService.smaller_than( prod.versions, verso, true, stability )
          prod.versions = new_range
        elsif verso.match(/^!=/)
          verso.gsub!("!=", "")
          new_range = VersionService.newest_but_not( prod.versions, verso, true, stability)
          prod.versions = new_range
        end
      end
      highest_version = VersionService.newest_version_from( prod.versions, stability )
      if highest_version
        dependency.version_requested = highest_version.to_s
      else
        dependency.version_requested = version
      end
      dependency.comperator = "="

    when version.match(/.\*$/)
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

    when version.empty? || version.match(/^\*$/)
      # This case is not allowed. But we handle it anyway. Because we are fucking awesome!
      dependency.version_requested = VersionService.newest_version_number( product.versions, dependency.stability )
      dependency.version_label = "*"
      dependency.comperator = "="

    when version.match(/^>=/)
      # Greater than or equal to
      version.gsub!(">=", "")
      version.gsub!(" ", "")
      greater_than_or_equal = VersionService.greater_than_or_equal( product.versions, version)
      dependency.version_requested = greater_than_or_equal.version
      dependency.comperator = ">="

    when version.match(/^>/)
      # Greater than version
      version.gsub!(">", "")
      version.gsub!(" ", "")
      greater_than = VersionService.greater_than( product.versions, version)
      dependency.version_requested = greater_than.version
      dependency.comperator = ">"

    when version.match(/^<=/)
      # Less than or equal to
      version.gsub!("<=", "")
      version.gsub!(" ", "")
      smaller_or_equal = VersionService.smaller_than_or_equal( product.versions, version )
      dependency.version_requested = smaller_or_equal.version
      dependency.comperator = "<="

    when version.match(/^\</)
      # Less than version
      version.gsub!("\<", "")
      version.gsub!(" ", "")
      smaller_than = VersionService.smaller_than( product.versions, version )
      dependency.version_requested = smaller_than.version
      dependency.comperator = "<"

    when version.match(/^!=/)
      # Not equal to version
      version.gsub!("!=", "")
      version.gsub!(" ", "")
      newest_but_not = VersionService.newest_but_not( product.versions, version )
      dependency.version_requested = newest_but_not.version
      dependency.comperator = "!="

    when version.match(/^~/)
      # Approximately greater than -> Pessimistic Version Constraint
      version.gsub!("~", "")
      version.gsub!(" ", "")
      highest_version = VersionService.version_tilde_newest( product.versions, version )
      if highest_version
        dependency.version_requested = highest_version.to_s
      else
        dependency.version_requested = version
      end
      dependency.comperator = "~"

    else # =
      dependency.version_requested = version
      dependency.comperator = "="
    end

  end

  # TODO write tests
  #
  def dependency_in_repositories? dependency, data
    return false if (dependency.nil? || data.nil?)
    repos = data['repositories']
    return false if (repos.nil? || repos.empty? || repo['package'].nil?)
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

  def init_project url
    project              = Project.new
    project.project_type = Project::A_TYPE_COMPOSER
    project.language     = Product::A_LANGUAGE_PHP
    project.url          = url
    project
  end

  private

    def init_projectdependency key, product
      dependency          = Projectdependency.new
      dependency.name     = key
      dependency.language = Product::A_LANGUAGE_PHP
      if product
        dependency.prod_key        = product.prod_key
        dependency.version_current = product.version
      end
      dependency
    end

    # This method exist in CommonParser, too!
    # This is just a copy with a different implementation for Composer!
    #
    def update_requested_with_current dependency, product
      if product && product.version
        dependency.version_requested = VersionService.newest_version_number( product.versions, dependency.stability )
      else
        dependency.version_requested = "UNKNOWN"
      end
      dependency
    end

    def print_backtrace e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
    end

end
