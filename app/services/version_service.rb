class VersionService


  def self.newest_version(versions, stability = "stable")
    return nil if versions.nil? || versions.empty?
    filtered = Array.new
    versions.each do |version|
      if VersionTagRecognizer.does_it_fit_stability? version.version, stability
        filtered << version
      end
    end
    filtered = versions if filtered.empty?
    sorted = Naturalsorter::Sorter.sort_version_by_method_desc( filtered, "version" )
    sorted.first
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
    new_st = "#{value}"
    if value.match(/./)
      splits = value.split(".")
      new_end = splits.size - 2
      new_slice = splits[0..new_end]
      new_st = new_slice.join(".")
    end
    starter = "#{new_st}."

    versions_group1 = self.versions_start_with( versions, starter )
    versions_filtered = Array.new
    versions_group1.each do |version|
      if Naturalsorter::Sorter.bigger_or_equal?(version.version, value)
        versions_filtered.push(version)
      end
    end
    VersionService.newest_version_from( versions_filtered )
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
    versions.each do |version|
      if version.version.match(/^#{val}/)
        result.push(version)
      end
    end
    result
  end


  # TODO write test for it
  def self.newest_but_not( versions, value, range=false)
    filtered_versions = Array.new
    versions.each do |version|
      if !version.version.match(/^#{value}/)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = VersionService.newest_version_from(filtered_versions)
    return get_newest_or_value(newest, value)
  end


  def self.greater_than( versions, value, range = false)
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.bigger?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = VersionService.newest_version_from(filtered_versions)
    return get_newest_or_value(newest, value)
  end


  def self.greater_than_or_equal( versions, value, range = false)
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.bigger_or_equal?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = VersionService.newest_version_from(filtered_versions)
    return get_newest_or_value(newest, value)
  end


  def self.smaller_than( versions, value, range = false)
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.smaller?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = VersionService.newest_version_from(filtered_versions)
    return get_newest_or_value(newest, value)
  end


  def self.smaller_than_or_equal( versions, value, range = false)
    filtered_versions = Array.new
    versions.each do |version|
      if Naturalsorter::Sorter.smaller_or_equal?(version.version, value)
        filtered_versions.push(version)
      end
    end
    return filtered_versions if range
    newest = VersionService.newest_version_from(filtered_versions)
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
    return nil if versions.nil? || versions.empty? || versions.size < 3
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
