class VersionService


  def self.newest_version(versions, stability = "stable")
    return nil if versions.nil? || versions.empty?
    filtered = Array.new
    versions.each do |version|
      next if version.version.eql?("dev-master")
      if VersionTagRecognizer.does_it_fit_stability? version.version, stability
        filtered << version
      end
    end
    filtered = versions if filtered.empty?
    sorted = Naturalsorter::Sorter.sort_version_by_method( filtered, "version", false )
    sorted.first
  end

  def self.versions_by_whitelist(versions, whitelist)
    whitelist = Set.new whitelist.to_a
    filtered = []
    versions.each do |ver|
      filtered << ver if whitelist.include? ver[:version]
    end
    filtered
  end

  def self.newest_version_number( versions, stability = "stable" )
    version = newest_version( versions, stability )
    return nil if version.nil?
    return version.version
  end


  def self.newest_version_from( versions, stability = "stable")
    return nil if !versions || versions.empty?
    VersionService.newest_version( versions, stability )
  end


  # TODO write test
  def self.newest_version_from_wildcard( versions, version_start, stability = "stable" )
    versions_filtered = versions_start_with( versions, version_start )
    return newest_version_number( versions_filtered, stability )
  end

  def self.version_approximately_greater_than_starter(value)
    if value.match(/\.0$/)
      new_end = value.length - 2
      return value[0..new_end]
    else
      return "#{value}."
    end
  end

  def self.version_tilde_newest( versions, value )
    return nil if value.nil?
    value = value.gsub("~", "")
    value = value.gsub(" ", "")
    upper_border = self.tile_border( value )
    greater_than = self.greater_than_or_equal( versions, value, true  )
    range = self.smaller_than( greater_than, upper_border, true )
    VersionService.newest_version_from( range )
  end

  def self.tile_border( value )
    return value if value.to_s.size == 1
    if value.match(/\./).nil? && value.match(/^[0-9\-\_a-zA-Z]*$/)
      return value.to_i + 1
    elsif value.match(/\./) && value.match(/^[0-9]+\.[0-9\-\_a-zA-Z]*$/)
      nums  = value.split(".")
      up    = nums.first.to_i + 1
      return "#{up}.0"
    elsif value.match(/\./) && value.match(/^[0-9]+\.[0-9]+\.[0-9\-\_a-zA-Z]*$/)
      nums = value.split(".")
      up   = nums[1].to_i + 1
      return "#{nums[0]}.#{up}"
    end
    nil
  end

  def self.version_range( versions, start, stop)
    # get all versions from range ( >=start <=stop )
    range = Array.new
    versions.each do |version|
      fits_stop  = Naturalsorter::Sorter.smaller_or_equal?( version.version, stop  )
      fits_start = Naturalsorter::Sorter.bigger_or_equal?(  version.version, start )
      if fits_start && fits_stop
        range.push(version)
      end
    end
    range
  end


  def self.versions_start_with( versions, val )
    result = Array.new
    return result if versions.nil? || versions.empty?
    version_matcher = Regexp.new("^#{val.to_s}")
    versions.each do |version|
      if version.version.match(/^#{val}/)
        result.push(version)
      end
    end
    result
  end

  def self.versions_by_comperator(versions, operator, value, range = true)
    matching_versions = case operator
    when '!=' then not_equal(versions, value, range)
    when '<'  then smaller_than(versions, value, range)
    when '<=' then smaller_than_or_equal(versions, value, range)
    when '>'  then greater_than(versions, value, range)
    when '>=' then greater_than_or_equal(versions, value, range)
    else equal(versions, value, range)
    end
  end

  # TODO write test for it
  def self.newest_but_not( versions, value, range=false, stability = "stable")
    filtered_versions = Array.new
    versions.each do |version|
      if !version.version.match(/^#{value}/)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = VersionService.newest_version_from(filtered_versions, stability)
    return get_newest_or_value(newest, value)
  end


  def self.equal( versions, value, range = false, stability = "stable")
    filtered_versions = Array.new
    versions.each do |ver|
      filtered_versions << ver if ver.version == value.to_s
    end
    return filtered_versions if range
    newest = VersionService.newest_version_from(filtered_versions, stability)
    return get_newest_or_value(newest, value)
  end


  def self.not_equal( versions, value, range = false, stability = "stable")
    filtered_versions = Array.new
    versions.each do |version|
      if version.version != value
        filtered_versions << version
      end
    end
    return filtered_versions if range
    newest = VersionService.newest_version_from(filtered_versions, stability)
    return get_newest_or_value(newest, value)
  end


  def self.greater_than( versions, value, range = false, stability = "stable")
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.bigger?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = VersionService.newest_version_from(filtered_versions, stability)
    return get_newest_or_value(newest, value)
  end


  def self.greater_than_or_equal( versions, value, range = false, stability = "stable")
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.bigger_or_equal?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = VersionService.newest_version_from(filtered_versions, stability)
    return get_newest_or_value(newest, value)
  end


  def self.smaller_than( versions, value, range = false, stability = "stable")
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.smaller?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = VersionService.newest_version_from(filtered_versions, stability)
    return get_newest_or_value(newest, value)
  end


  def self.smaller_than_or_equal( versions, value, range = false, stability = "stable")
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.smaller_or_equal?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = VersionService.newest_version_from(filtered_versions, stability)
    return get_newest_or_value(newest, value)
  end


  def self.update_version_data( product, persist = true )
    return nil if product.nil?
    versions = product.versions
    return nil if versions.nil? || versions.empty?
    newest_stable_version = self.newest_version( versions )
    return nil if newest_stable_version.version.eql?( product.version)
    product.version      = newest_stable_version.version
    product.version_link = newest_stable_version.link
    product.save if persist
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
  end


  # TODO test
  def self.average_release_time( versions )
    return nil if versions.nil? || versions.empty? || versions.size == 1
    released_versions = self.versions_with_rleased_date( versions )
    return nil if released_versions.nil? || released_versions.empty? || released_versions.size < 3
    sorted_versions = released_versions.sort! { |a,b| a.released_at <=> b.released_at }
    first = sorted_versions.first.released_at
    last  = sorted_versions.last.released_at
    return nil if first.nil? || last.nil?
    diff = last.to_i - first.to_i
    diff_days = diff / 60 / 60 / 24
    average = diff_days / sorted_versions.size
    average
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    nil
  end

  def self.estimated_average_release_time( versions )
    return nil if versions.nil? || versions.empty? || versions.size == 1
    sorted_versions = versions.sort! { |a,b| a.created_at <=> b.created_at }
    first = sorted_versions.first.created_at
    last  = sorted_versions.last.created_at
    return nil if first.nil? || last.nil?
    diff = last.to_i - first.to_i
    diff_days = diff / 60 / 60 / 24
    average = diff_days / sorted_versions.size
    average
  rescue => e
    p e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    nil
  end


  private

    def self.versions_with_rleased_date( versions )
      return nil if versions.nil? || versions.empty?
      new_versions = Array.new
      versions.each do |version|
        new_versions << version if !version.released_at.nil?
      end
      new_versions
    end

    def self.get_newest_or_value(newest, value)
      if newest.nil?
        version = Version.new
        version.version = value
        return version
      else
        return newest
      end
    end

end
