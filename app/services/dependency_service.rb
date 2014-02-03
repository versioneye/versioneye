class DependencyService


  def self.dependencies_outdated?( dependencies )
    return false if dependencies.nil? || dependencies.empty?
    dependencies.each do |dependency|
      return true if self.outdated?( dependency )
    end
    false
  end


  def self.cache_outdated?( dependency )
    key = "#{dependency.id.to_s}_outdated?"
    outdated = Rails.cache.read( key )
    return outdated if outdated

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

    self.update_parsed_version( dependency, product )

    return false if newest_product_version.eql?( dependency.parsed_version )
    newest_version = Naturalsorter::Sorter.sort_version([dependency.parsed_version, newest_product_version]).last
    return false if newest_version.eql?( dependency.parsed_version )
    return true
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    return false
  end


  def self.update_parsed_version dependency, product = nil
    if dependency.version.to_s.empty?
      dependency.parsed_version = "unknown"
      return
    end
    if product.nil?
      product  = find_product( dependency.prod_type, dependency.language, dependency.dep_prod_key )
    end
    parser   = ParserStrategy.parser_for( dependency.prod_type, '' )
    proj_dep = Projectdependency.new
    parser.parse_requested_version( dependency.version, proj_dep, product )
    dependency.parsed_version = proj_dep.version_requested
  end


  private


    def self.find_product prod_type, language, dep_prod_key
      if dep_prod_key.eql?("php/php") or dep_prod_key.eql?("php")
        language = Product::A_LANGUAGE_C
      end
      if prod_type.eql?(Project::A_TYPE_BOWER)
        return Product.fetch_bower dep_prod_key
      else
        return Product.fetch_product( language, dep_prod_key )
      end
    end

end
