class BowerParser < CommonParser
  attr_reader :rules 
  def initialize
    #ATOMIC RULES
    numeric = '\d+' #numeric identifier
    non_numeric =  '\d*[a-zA-Z\-][\\w\-]*' #0 or more numbers before character
    prerelease_ident = "#{numeric}|#{non_numeric}"
    build_ident = "[\\w-]*"
    gtlt = "(?<comparator>(?:<|>)?=?)"
    xrange_ident = "#{numeric}|x|X|\\*"
    tilde = "(?:~>?)"
    caret = "(?:\\^)"
    #VERSION MATCHERS
    ign = "(?:[v=\\s]*)" # ignore those chars before version
    prerelease_info = "[-]*(?<prerelease>#{prerelease_ident}(\\.#{prerelease_ident})*)" #hyphen, followed 1 or more dot-separated pre-release version identifiers

    build_info = "\\+(?<build>#{build_ident}(\\.#{build_ident})*)" # for build metadata = +

    main_version =  "(?<version>(#{numeric})\\.(#{numeric})\\.(#{numeric}))"
    
    #full version = main version, optionally followed by prerelease or build info
    full_version = "^#{ign}#{main_version}(#{prerelease_info})?(#{build_info})?$"

    #x range version, smt like 2.* or 2.x.X
    xrange = %Q{
      (?<version>
        (#{xrange_ident})
        (?:\\.(#{xrange_ident})
        (?:\\.(#{xrange_ident})
        (?:(#{prerelease_info}))?)?)?
      )
    }
    asterisk_version = "^#{ign} \\s* #{xrange}$" #1.* or 1.2.x
    xrange_version = "^#{gtlt} \\s* #{ign}#{xrange}$" # '> 1.*'
    tilde_version = "^\\s* #{tilde} \\s* #{xrange}$"
    caret_version = "^\\s* #{caret} \\s* #{xrange}$"
    hyphen_version = %Q[
      ^\\s* \\s* 
      (?<start> #{xrange}) 
        \\s+ - \\s+ 
      (?<end> #{xrange}) \\s* $
    ]
    star_version = "(<|>)?=?\\s*\\*"
    #initialize set of rules 
    @rules = {
      main_version: Regexp.new(main_version, Regexp::EXTENDED),
      full_version: Regexp.new(full_version, Regexp::EXTENDED),
      asterisk_version: Regexp.new(asterisk_version, Regexp::EXTENDED),
      xrange_version: Regexp.new(xrange_version, Regexp::EXTENDED),
      tilde_version: Regexp.new(tilde_version, Regexp::EXTENDED),
      caret_version: Regexp.new(caret_version, Regexp::EXTENDED),
      hyphen_version: Regexp.new(hyphen_version, Regexp::EXTENDED),
      star_version: Regexp.new(star_version, Regexp::EXTENDED)
    }
  end

  def parse ( url )
    return nil if url.nil? || url.empty?
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
    product    = Product.fetch_product( Product::A_LANGUAGE_JAVASCRIPT, key )
    dependency = init_dependency( product, key )
    parse_requested_version( value, dependency, product )
    project.out_number     += 1 if dependency.outdated?
    project.unknown_number += 1 if product.nil?
    project.projectdependencies.push dependency
  end

  # It is important that this method is not writing int the database!
  #
  def parse_requested_version(version, dependency, product)
    if product.nil?
      dependency.version_requested = version
      dependency.version_label     = version
      return
    end


    if (m = version.match(self.rules[:star_version]))
      version_data = {version: product.version, label: "*", comperator: "="}
    elsif (m = version.match(self.rules[:main_version]))
      version_data = {version: m[:version], label: m[:version], comperator: "="}
    elsif (m = version.match(self.rules[:asterisk_version]))
      ver = ver.gsub(/[\s|x]+/i)
      versions = VersionService.versions_start_with(product.versions, ver)
      highest_version = VersionService.newest_version_from(versions)
      version_data = {version: highest_version.version || version, 
                      label: m[:version], 
                      comperator: "="}
    elsif (m = version.match(self.rules[:xrange_version]))
      ver = m[:version]
      case m[:comperator]
      when "<" 
        newest = VersionService.smaller_than(product.versions, ver)
      when "<="
        newest = VersionService.smaller_than_equal(product.versions, ver)
      when ">"
        newest = VersionService.greater_than(product.versions, ver)
      when ">="
        newest = VersionService.greater_than_equal(product.versions, ver)
      end
      if newest
        version_data = {version: newest.version, label: ver, comperator: m[:comperator]}
      else
        Rails.debug.error("Couldnt find latest versions for #{product[:name]} using version: `#{ver}`")
        version_data = {version: version, label: ver, comperator: m[:comperator]}
      end
    elsif (m = version.match(self.rules[:tilde_version]))
      highest_version = VersionService.version_tilde_newest(product.versions, m[:version])
      version_data = {version: highest_version.version || m[:version], label: m[:version], comperator: "~"}
    elsif (m = version.match(self.rules[:caret_version]))
      if m[:version] =~ /0\.0\.\d+/ 
        version_data = {version: m[:version], label: m[:version], comperator: "="}
      else
        highest_version = VersionService.version_tilde_newest(product.versions, m[:version])
        version_data = {
          version: highest_version.version || m[:version], 
          label: m[:version], 
          comperator: "^"
        }
      end

    elsif (m = version.match(self.rules[:hyphen_version]))
      version_range = VersionService.version_range(product.versions, m[:start], m[:end])
      highest_version = VersionService.newest_version_from(version_range)
      version_data = {
        version: highest_version.version || m[:end],
        label: version,
        comperator: "="
      }
    else
      Rails.debug.error("Version `#{version}` for #{product[:name]} doesnt match with any rules. Probably misformed.")
      version_data = { version: product.version, label: "*", comperator: "="}
    end

    dependency.version_requested = version_data[:version]
    dependency.version_label = version_data[:label]
    dependency.comperator = version_data[:comperator]

    dependency
  end
  
  #TODO: try to add more info ~ licence, github etc
  def init_project( url, data )
    project = Project.new
    project.project_type = Project::A_TYPE_BOWER
    project.language     = Product::A_LANGUAGE_JAVASCRIPT
    project.url          = url
    project.name         = data['name']
    project.description  = data['description']
    project
  end

  def fetch_dependencies( data )
    dependencies = data['dependencies']
    dev_dependencies = data['devDependencies'] #Shouldnt be separated?
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
    dependency.language = Product::A_LANGUAGE_JAVASCRIPT
    if product
      dependency.prod_key        = product.prod_key
      dependency.version_current = product.version
    end
    dependency
  end

end
