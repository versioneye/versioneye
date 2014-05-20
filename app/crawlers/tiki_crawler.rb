class TikiCrawler


  def self.logger
    ActiveSupport::BufferedLogger.new('log/tiki.log')
  end

  @@composer_tiki_page = 'http://composer.tiki.org/'


  def self.crawl
    start_time = Time.now
    packages = get_first_level_list
    packages.each do |package|
      crawle_package package
    end
    duration = Time.now - start_time
    self.logger.info(" *** This crawl took #{duration} *** ")
    return nil
  end


  def self.get_first_level_list
    body = JSON.parse HTTParty.get('http://composer.tiki.org/packages.json' ).response.body
    body['packages']
  end


  def self.crawle_package package
    return nil if package.nil? || package.empty?

    versions = package.last
    return nil if versions.nil? || versions.empty?

    versions.each do |version_obj|
      version_object = version_obj.last
      self.process_version version_object
    end
  rescue => e
    self.logger.error "ERROR in crawle_package Message:   #{e.message}"
    self.logger.error e.backtrace.join('\n')
  end


  def self.process_version version_object
    name           = version_object['name']
    product = find_or_create_product name

    version_number = version_object['version']
    if version_number && version_number.match(/v[0-9]+\..*/)
      version_number.gsub!('v', '')
    end

    db_version = product.version_by_number version_number
    if db_version.nil?
      create_new_version( product, version_number, version_object )
      return nil
    end
    if version_number.match(/\Adev\-/)
      Dependency.remove_dependencies Product::A_LANGUAGE_PHP, product.prod_key, version_number
      ComposerUtils.create_dependencies product, version_number, version_object
      Versionarchive.remove_archives Product::A_LANGUAGE_PHP, product.prod_key, version_number
      ComposerUtils.create_archive     product, version_number, version_object
    end
  end


  def self.find_or_create_product name
    product = Product.find_or_create_by( prod_key: name, language: Product::A_LANGUAGE_PHP )
    product.reindex       = true
    product.name          = name
    product.name_downcase = name.downcase
    product.prod_type     = Project::A_TYPE_COMPOSER
    if product.repositories.nil? || product.repositories.empty?
      repository = Repository.new({:src => @@composer_tiki_page, :repotype => Project::A_TYPE_COMPOSER })
      product.repositories.push repository
    end
    product.save
    Versionlink.create_project_link( Product::A_LANGUAGE_PHP, product.prod_key, @@composer_tiki_page, 'Tiki Page' )
    product
  end


  def self.create_new_version product, version_number, version_obj
    version_db                 = Version.new({version: version_number})
    if version_obj['time']
      version_db.released_string = version_obj['time']
      version_db.released_at     = DateTime.parse(version_obj['time'])
    end
    product.versions.push version_db
    product.reindex = true
    product.save

    self.logger.info " -- PHP Package: #{product.prod_key} -- with new version: #{version_number}"

    CrawlerUtils.create_newest product, version_number, logger
    CrawlerUtils.create_notifications product, version_number, logger

    Versionlink.create_versionlink product.language, product.prod_key, version_number, version_obj['homepage'], "Homepage"

    ComposerUtils.create_license( product, version_number, version_obj )
    ComposerUtils.create_developers version_obj['authors'], product, version_number
    ComposerUtils.create_archive product, version_number, version_obj
    ComposerUtils.create_dependencies product, version_number, version_obj
  rescue => e
    self.logger.error "ERROR in create_new_version Message:   #{e.message}"
    self.logger.error e.backtrace.join('\n')
  end

end
