class DependencyService


  def self.cache_outdated?( dependency )
    key = "#{dependency.id.to_s}_outdated?"
    outdated = Rails.cache.read( key )
    return outdated if !outdated.nil?

    outdated = self.outdated?( dependency )
    Rails.cache.write( key, outdated, timeToLive: 6.hour )
    outdated
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    return false
  end


  def self.outdated?( dependency )
    product = dependency.product
    return false if product.nil?
    newest_product_version = VersionService.newest_version_number( product.versions )
    dependency.current_version = newest_product_version
    dependency.save

    project_dependency = Projectdependency.new
    parser = ParserStrategy.parser_for( dependency.prod_type, '')
    parser.parse_requested_version( dependency.version, project_dependency, product)
    version_requested = project_dependency.version_requested

    return false if newest_product_version.eql?( version_requested )
    newest_version = Naturalsorter::Sorter.sort_version([version_requested, newest_product_version]).last
    return false if newest_version.eql?( version_requested )
    return true
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    return false
  end


  def self.dependencies_outdated?( dependencies )
    return false if dependencies.nil? || dependencies.empty?
    dependencies.each do |dependency|
      return true if self.outdated?( dependency )
    end
    false
  end


end
