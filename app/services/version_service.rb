class VersionService

  attr_accessor :product #, :product_class

  def initialize product, product_class = Product
    self.product       = product
    # self.product_class = product_class
  end

  def sorted_versions
    Naturalsorter::Sorter.sort_version_by_method_desc( versions, "version" )
  end

  def newest_version( stability = "stable")
    return nil if versions.nil? || versions.empty?
    filtered = Array.new
    versions.each do |version|
      if VersionTagRecognizer.does_it_fit_stability? version.version, stability
        filtered << version
      end
    end
    if filtered.empty?
      filtered = versions
    end
    sorted = Naturalsorter::Sorter.sort_version_by_method_desc( filtered, "version" )
    return sorted.first
  end

  def newest_version_number( stability = "stable" )
    version = newest_version( stability )
    return nil if version.nil?
    return version.version
  end

  # TODOO
  def self.newest_version_from(versions, stability = "stable")
    return nil if !versions || versions.empty?
    product = Product.new({:versions => versions})
    version_service = VersionService.new( product )
    version_service.newest_version( stability )
  end

  def newest_version_from_wildcard( version_start, stability = "stable" )
    versions = versions_start_with( version_start )
    product = Product.new({:versions => versions})
    return product.newest_version_number stability
  end

  def version_by_number( searched_version )
    versions.each do |version|
      return version if version.version.eql?(searched_version)
    end
    nil
  end

  def self.version_approximately_greater_than_starter(value)
    if value.match(/\.0$/)
      new_end = value.length - 2
      return value[0..new_end]
    else
      return "#{value}."
    end
  end

  def version_tilde_newest(value)
    new_st = "#{value}"
    if value.match(/./)
      splits = value.split(".")
      new_end = splits.size - 2
      new_slice = splits[0..new_end]
      new_st = new_slice.join(".")
    end
    starter = "#{new_st}."

    versions_group1 = self.versions_start_with( starter )
    versions = Array.new
    versions_group1.each do |version|
      if Naturalsorter::Sorter.bigger_or_equal?(version.version, value)
        versions.push(version)
      end
    end
    VersionService.newest_version_from(versions)
  end

  def version_range(start, stop)
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

  def versions_start_with(val)
    result = Array.new
    versions.each do |version|
      if version.version.match(/^#{val}/)
        result.push(version)
      end
    end
    result
  end

  def newest_but_not(value, range=false)
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

  def greater_than(value, range = false)
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

  def greater_than_or_equal(value, range = false)
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

  def smaller_than(value, range = false)
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

  def smaller_than_or_equal(value, range = false)
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

  def versions_empty?
    versions.nil? || versions.size == 0 ? true : false
  end

  def wouldbenewest?(version)
    current = newest_version_number()
    return false if current.eql? version
    newest = Naturalsorter::Sorter.get_newest_version(current, version)
    return true if version.eql? newest
    return false
  end

  def update_version_data( persist = true )
    return nil if self.versions.nil? || self.versions.empty?
    newest_stable_version = self.newest_version
    return nil if newest_stable_version.version.eql?(self.version)
    self.version = newest_stable_version.version
    self.version_link = newest_stable_version.link
    self.save if persist
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
  end

  def versions_with_rleased_date
    return nil if versions.nil? || versions.empty?
    new_versions = Array.new
    versions.each do |version|
      new_versions << version if !version.released_at.nil?
    end
    new_versions
  end

  def average_release_time
    return nil if versions.nil? || versions.empty? || versions.size < 3
    released_versions = versions_with_rleased_date
    return nil if released_versions.nil? || released_versions.empty? || released_versions.size < 3
    sorted_versions = released_versions.sort! { |a,b| a.released_at <=> b.released_at }
    first = sorted_versions.first.released_at
    last = sorted_versions.last.released_at
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

  def copy_released_versions
    new_versions = Array.new
    versions.each do |version|
      new_versions << version if version.released_string
    end
    self.versions = new_versions
    self.save
  end

  private

    def versions
      self.product.versions
    end

    def get_newest_or_value(newest, value)
      if newest.nil?
        version = Version.new
        version.version = value
        return version
      else
        return newest
      end
    end

end
