class CocoapodsPackageManager < PackageManager

  # Public: put the best version of product into dependency
  #
  # version_constraint - A String or Array of Strings, each with comperator and version number
  # dependency - the dependency object, this will be updated through the method
  # product    - the product requested by the dependency. Can be nil. \
  #              Has potentially multiple versions and version_constraint determines \
  #              which one to choose.
  #
  # Examples
  #
  #
  # Returns nothing but updates the dependency
  def self.parse_requested_version(version_constraint, dependency, product = nil)

    if version_constraint.to_s.empty?
      update_requested_with_current( dependency, product )
      return
    end

    constraint = parse_version_constraint( version_constraint )
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
    when ">"
      VersionService.greater_than( version_candidates, version_number ).version
    when ">="
      VersionService.greater_than_or_equal( version_candidates, version_number ).version
    when "<"
      VersionService.smaller_than( version_candidates, version_number ).version
    when "<="
      VersionService.smaller_than_or_equal( version_candidates, version_number ).version
    when "~>"
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
end