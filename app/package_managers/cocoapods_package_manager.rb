class CocoapodsPackageManager < PackageManager

  # Public: put the best version of product into dependency
  #
  # version_constraint - A String or Array of Strings, each with comperator and version number
  # project_dependency - the Projectdependency object, this will be updated through the method
  # product            - the Product requested by the dependency. Can be nil. \
  #                      Has potentially multiple versions and version_constraint determines \
  #                      which one to choose.
  #
  #
  # Returns nothing but updates the dependency
  def self.parse_requested_version(version_constraint, project_dependency, product = nil)

    if version_constraint.to_s.empty?
      update_requested_with_current( project_dependency, product )
      return
    end

    if product.nil?
      project_dependency.version_requested = version_constraint
      project_dependency.version_label     = version_constraint
      return
    end

    parsed = parse_version_constraint( version_constraint )
    chosen = choose_version( parsed[:comperator], parsed[:version_requested], product.versions)
    project_dependency.version_label     = version_constraint
    project_dependency.comperator        = parsed[:comperator]
    project_dependency.version_requested = chosen
  end


  # Public: uses a RegExp to parse a version_constraint string
  #
  # version_constraint - a String. starts with a comperator, ends with a version-number
  #
  # Examples
  #
  #   parse_version_constraint '~> 1.2.3'
  #   # => {:comperator => '~>', :version_requested => '1.2.3'}
  #
  # a Hash with keys :comperator and :version_requested
  VERSION_REGEXP = /^(=|!=|>=|>|<=|<|~>)\s*(\d(\.\d(\.\d)?)?)/
  def self.parse_version_constraint version_constraint
    version_constraint.match VERSION_REGEXP
    comperator, version = $1, $2
    return {:comperator => comperator, :version_requested => version}
  end


  # Public: choose THE version from an array of version candidates, use comperator and version_number.
  #
  # comperator - a string, should be used to compare version_number to version_candidates
  # version_number - version number, usually min or maximum bound
  # version_candidates - an array of possible version candidates
  #
  # Examples
  #
  #   choose_version('>', '0', ['1.1', '1.0'])
  #   # => '1.1'
  #
  # Returns String of chosen version number.
  def self.choose_version(comperator, version_number, version_candidates)
    case comperator
    when '>'
      VersionService.greater_than( version_candidates, version_number ).version
    when '>='
      VersionService.greater_than_or_equal( version_candidates, version_number ).version
    when '<'
      VersionService.smaller_than( version_candidates, version_number ).version
    when '<='
      VersionService.smaller_than_or_equal( version_candidates, version_number ).version
    when '~>'
      starter         = VersionService.version_approximately_greater_than_starter( version_number )
      possible_vers   = VersionService.versions_start_with( version_candidates, starter )
      highest_version = VersionService.newest_version_from( possible_vers )
      return highest_version.version if highest_version
      return version_number
    else
      version
    end
  rescue => e
    Rails.logger.error e.message
    version_number
  end

  # Public: parse a string into [spec, subspec] array.
  #
  # string - the string that will be parsed
  # Examples
  #
  #   spec_subspec 'ShareKit/Facebook'
  #   # => ['ShareKit', 'Facebook']
  #
  #   spec_subspec 'ShareKit'
  #   # => ['ShareKit']
  #
  # Returns nil if the String is nil or empty, or an array containing [spec,subspec]
  def self.spec_subspec string
    return nil if string.nil? || string.empty?
    string.split('/')
  end

end

## Monkey Patch CocoaPods, so we are able to parse from URLs

module Pod

  class Podfile
    # Configures a new Podfile from the given url.
    #
    # @param  [String] url
    #         The url which will configure the podfile with the DSL.
    #
    # @return [Podfile] the new Podfile
    #
    def self.from_url(url)
      podfile = nil
      open(url) do |io|
        begin
          podfile = Podfile.new do
            # rubocop:disable Eval
            eval(io.string, nil, url)
            # rubocop:enable Eval
          end
        rescue Exception => e
          Rails.logger.error e
          message = "Invalid url `#{url}`: #{e.message}"
          raise DSLError.new(message, url, e.backtrace)
        end
      end

      podfile

    end
  end

  class Lockfile
    def self.from_url(url)
      open(url) do |io|
        require 'yaml'
        hash = YAML.load(io)

        unless hash && hash.is_a?(Hash)
          raise Informative, "Invalid Lockfile in `#{url}`"
        end

        lockfile = Lockfile.new(hash)
        lockfile.defined_in_file = url
        lockfile
      end
    end
  end

end
