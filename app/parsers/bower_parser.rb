class BowerParser < CommonParser
  attr_reader :rules

  def initialize
    #ATOMIC RULES
    numeric = '\d+' #numeric identifier
    non_numeric =  '\d*[a-zA-Z\-][\\w\-]*' #0 or more numbers before character
    prerelease_ident = "#{numeric}|#{non_numeric}"
    ident = "[\\w\\-\\.]+"
    build_ident = "[\\w-]*"
    gtlt = "(?<comperator>(?:<|>)?=?)"
    xrange_ident = "#{numeric}|x|X|\\*"
    tilde = "(?:~>?)"
    caret = "(?:\\^)"
    #VERSION MATCHERS
    ign = "(?:[v=\\s]*)" # ignore those chars before version
    prerelease_info = "[-]*(?<prerelease>#{prerelease_ident}(\\.#{prerelease_ident})*)" #hyphen, followed 1 or more dot-separated pre-release version identifiers

    build_info = "\\+(?<build>#{build_ident}(\\.#{build_ident})*)" # for build metadata = +

    main_version =  "(?<version>(#{numeric})(\\.(#{numeric})(\\.(#{numeric}))?)?)"

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
    commit_version = "(?<owner>#{ident})/(?<repo>#{ident})\\#(?<sha>#{ident})"

    #initialize set of rules
    @rules = {
      main_version: Regexp.new(main_version, Regexp::EXTENDED),
      full_version: Regexp.new(full_version, Regexp::EXTENDED),
      asterisk_version: Regexp.new(asterisk_version, Regexp::EXTENDED),
      xrange_version: Regexp.new(xrange_version, Regexp::EXTENDED),
      tilde_version: Regexp.new(tilde_version, Regexp::EXTENDED),
      caret_version: Regexp.new(caret_version, Regexp::EXTENDED),
      hyphen_version: Regexp.new(hyphen_version, Regexp::EXTENDED),
      star_version: Regexp.new(star_version, Regexp::EXTENDED),
      commit_version: Regexp.new(commit_version, Regexp::EXTENDED)
    }
  end

  def cleanup_version(version_label)
    version_label.to_s.gsub(/^\D+/, "") #removes all non-numerical before version
  end

  def parse ( url )
    return nil if url.nil? || url.empty?

    data = self.fetch_response_body_json( url )
    return nil if data.nil?

    dependencies = fetch_dependencies( data )
    return nil if dependencies.nil?
    project = init_project( url, data )

    dependencies.each do |package_name, version_label|
      parse_version_label( package_name.to_s.downcase, version_label, project )
    end
    project.dep_number = project.dependencies.size

    project
  end

  def trim_text(text)
    text = text.to_s.strip
    text.gsub(/\s+ - \s+/x, '|-|')
  end

  def parse_version_label(package_name, version_label, project)
    product    = fetch_product( package_name )
    dependency = init_dependency( product, package_name )
    if product.nil?
      Rails.logger.error "#{self.class}.parse_version_label | Cant find product for #{Project::A_TYPE_BOWER}, `#{package_name}`"
      project.unknown_number += 1
    else
      dependency = parse_requested_version(version_label, dependency, product)
    end
    project.out_number     += 1 if dependency.outdated?
    project.projectdependencies.push dependency
    project
  end

  def parse_requested_version(version_label, dependency, product)
    version_label = version_label.strip
    package_name = dependency[:name]
    if trim_text(version_label).split(/\s+/).count < 2
      newest_version = parse_single_version(package_name, version_label, product)
    else
      newest_version = parse_combined_versions(package_name, version_label, product)
    end

    dependency.update_attributes({
      #version_label: newest_version[:label],
      version_requested: newest_version[:version],
      comperator: newest_version[:comperator]
    })

    dependency
  end

  def parse_combined_versions(package_name, version_label, product)
    version_label = trim_text(version_label) #concanate temporaly hyphen-versions
    versions = version_label.split(/\s+/)
    whitelisted_labels = Set.new []
    set_operator = "&"
    versions.each do |version|
      if version == "||"
        set_operator = "|"
        next
      end
      version = version.to_s.strip.gsub(/ \|-\| /x, ' - ') #restore hyphen version and remove reduntant spaces

      version_data = parse_version_data(package_name, version, product)
      if version_data.nil?
        Rails.logger.error "Cant parse version `#{version_label}` for #{package_name}."
        return nil
      end

      matching_labels = VersionService.versions_by_comperator(product.versions, version_data[:comperator], version_data[:label]).to_a.map {|ver| ver[:version]}
      matching_labels = Set.new matching_labels.to_a

      whitelisted_labels = matching_labels if whitelisted_labels.empty?
      if set_operator == '&'
        whitelisted_labels = whitelisted_labels & matching_labels
      else set_operator == '|'
        whitelisted_labels = whitelisted_labels | matching_labels
      end
      set_operator = "&" if set_operator == "|" #mark set_operator as used and use default value
    end

    allowed_versions = VersionService.versions_by_whitelist(product.versions, whitelisted_labels)
    #TODO: what if allowed_versions nil? - tautology or missing versions on DB??
    newest_version = VersionService.newest_version(allowed_versions)
    if newest_version.nil?
      Rails.logger.error "#{self.class}.parse_combined_versions| Didnt get any versions for `#{package_name}`:`#{version_label}`"
      newest_version = Version.new version: 'unknown'
    end

    newest_version[:comperator] = '=' #TODO: is it correct?
    newest_version[:label] = versions
    newest_version
  end

  def parse_single_version(package_name, version, product)
    version_data = parse_version_data(package_name, version, product)
    Version.new(version: version_data[:version],
                label: version_data[:label],
                comperator: version_data[:comperator],
                prerelease: version_data[:prerelease])
  end

  def parse_version_data(package_name, version, product)
    if product.nil?
      Rails.logger.error "parse_version_data | product is nil for #{package_name}: #{version}"
      return {
        version: cleanup_version(version),
        label: cleanup_version(version),
        comperator: '='
      }
    end

    if (m = version.match(self.rules[:star_version]))
      version_data = {version: product.version, label: "*", comperator: "="}
    elsif (m = version.match(self.rules[:full_version]))
      version_data = {
        version: m[:version],
        label: m[:version],
        comperator: "=",
        prerelease: (m[:prerelease].nil?) ? false : true
      }
    elsif (m = version.match(self.rules[:asterisk_version]))
      #matches versions as 1.x, 1.*, 1.x.*, 1.*.x
      ver = m[:version]
      version_root, _ = ver.split(/x|\*/)
      version_root = version_root.to_s.gsub(/\./, '\.')
      matching_versions = VersionService.versions_start_with(product.versions, version_root)
      newest_version = VersionService.newest_version(matching_versions)
      if newest_version
        version_label = newest_version.version
      else
        version_label = version_root.gsub(/\.$/, '') #just use prefix
      end
      version_data = {
        version: version_label,
        label: m[:version],
        comperator: "<="
      }
    elsif (m = version.match(self.rules[:xrange_version]))
      ver = m[:version]
      newest = VersionService.versions_by_comperator(product.versions, m[:comperator], m[:version], false)

      if newest
        version_data = {version: newest.version, label: ver, comperator: m[:comperator]}
      else
        Rails.debug.error("Couldnt find latest versions for #{product[:name]} using version: `#{ver}`")

        version_data = {version: ver, label: version, comperator: m[:comperator]}
      end
    elsif (m = version.match(self.rules[:tilde_version]))
      highest_version = VersionService.version_tilde_newest(product.versions, m[:version])
      version_label = m[:version]
      version_label = highest_version.version if highest_version
      version_data = {
        version: version_label,
        label: m[:version],
        comperator: "~"
      }
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
      ver_label = m[:end]
      ver_label = highest_version.version if highest_version
      version_data = {
        version: ver_label,
        label: version,
        comperator: "<="
      }

    elsif (m = version.match(self.rules[:commit_version]))
      version_data = {
        version: m[:sha],
        label: m[:sha],
        comperator: "="
      }
    else
      Rails.logger.error %Q{BowerParser.parse_version_data | Version `#{version}` for #{product[:name]}
                            doesnt match with any rules. Probably misformed.}
      version_data = { version: product.version, label: "*", comperator: "="}
    end
    version_data
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

  def fetch_product package_name
    name = package_name.downcase
    Product.where(prod_type: Project::A_TYPE_BOWER, name: name).first
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
