class PackagistCrawler

  def self.logger
    ActiveSupport::BufferedLogger.new('log/packagist.log')
  end

  def self.crawl
    crawl = self.crawle_object
    packages = PackagistCrawler.get_first_level_list
    packages.each do |name|
      PackagistCrawler.crawle_package name, crawl
    end
    crawl.duration = Time.now - crawl.created_at
    crawl.save
    self.logger.info(" *** This crawle took #{crawl.duration} *** ")
    return nil
  end

  def self.get_first_level_list
    body = JSON.parse HTTParty.get('http://packagist.org/packages/list.json' ).response.body
    body['packageNames']
  end

  def self.crawle_package name, crawl
    return nil if name.nil? || name.empty?
    self.logger.info "Crawle #{name}"

    resource     = "http://packagist.org/packages/#{name}.json"
    pack         = JSON.parse HTTParty.get( resource ).response.body
    package      = pack['package']
    package_name = package['name']
    versions     = package['versions']
    return nil if versions.nil? || versions.empty?

    product = PackagistCrawler.init_product package_name
    PackagistCrawler.update_product product, package

    packagist_page = "http://packagist.org/packages/#{package_name}"
    PackagistCrawler.update_packagist_link product, packagist_page

    versions.each do |version|
      version_number = String.new(version[0])
      version_obj = version[1]
      if version_number && version_number.match(/v[0-9]+\..*/)
        version_number.gsub!('v', '')
      end
      db_version = product.version_by_number version_number
      if db_version.nil?
        PackagistCrawler.create_new_version product, version_number, version_obj, crawl
      else
        PackagistCrawler.create_dependencies product, version_number, version_obj
        PackagistCrawler.create_download     product, version_number, version_obj
      end
    end
    VersionService.update_version_data( product )
  rescue => e
    self.logger.error "ERROR in crawle_package Message:   #{e.message}"
    self.logger.error e.backtrace.join("\n")
    PackagistCrawler.store_error crawl, e.message, e.backtrace, name
  end

  def self.init_product name
    product = Product.find_by_lang_key( Product::A_LANGUAGE_PHP, name )
    return product if product
    self.logger.info " -- New PHP Package - #{name}"
    Product.new({:reindex => true})
  end

  def self.update_product product, package
    name                  = package['name']
    product.prod_key      = name
    product.name          = name
    product.name_downcase = name.downcase
    product.description   = package['description']
    product.prod_type     = Project::A_TYPE_COMPOSER
    product.language      = Product::A_LANGUAGE_PHP
    product.save
  end

  def self.update_packagist_link product, packagist_page
    versionlink = Versionlink.find_by( Product::A_LANGUAGE_PHP, product.prod_key, packagist_page )
    return nil if versionlink
    versionlink = Versionlink.new({:name => "Packagist Page", :link => packagist_page, :prod_key => product.prod_key, :language => Product::A_LANGUAGE_PHP })
    versionlink.save
  end

  def self.create_new_version product, version_number, version_obj, crawl
    version_db                 = Version.new({version: version_number})
    version_db.released_string = version_obj['time']
    version_db.released_at     = DateTime.parse(version_obj['time'])
    product.versions.push version_db
    product.reindex = true
    product.save

    self.logger.info " -- PHP Package: #{product.prod_key} -- with new version: #{version_number}"

    CrawlerUtils.create_newest product, version_number, logger
    CrawlerUtils.create_notifications product, version_number, logger

    Versionlink.create_versionlink product.language, product.prod_key, version_number, version_obj['homepage'], "Homepage"

    self.create_license( product, version_number, version_obj )
    self.create_developers version_obj['authors'], product, version_number
    self.create_download product, version_number, version_obj
    self.create_dependencies product, version_number, version_obj
  rescue => e
    self.logger.error "ERROR in create_new_version Message:   #{e.message}"
    self.logger.error e.backtrace.join("\n")
    self.store_error crawl, e.message, e.backtrace, product.name
  end

  def self.create_download product, version_number, version_obj
    dist = version_obj['dist']
    return nil if dist.nil? || dist.empty?
    dist_url  = dist['url']
    dist_type = dist['type']
    dist_name = "#{product.name}.#{dist_type}"
    archive = Versionarchive.new({:language => Product::A_LANGUAGE_PHP, :prod_key => product.prod_key,
      :version_id => version_number, :name => dist_name, :link => dist_url})
    Versionarchive.create_if_not_exist_by_name( archive )
  end

  def self.create_dependencies product, version_number, version_obj
    require_dep = version_obj['require']
    PackagistCrawler.create_dependency require_dep, product, version_number, "require"

    require_dep = version_obj['require-dev']
    PackagistCrawler.create_dependency require_dep, product, version_number, "require-dev"

    require_dep = version_obj['replace']
    PackagistCrawler.create_dependency require_dep, product, version_number, "replace"

    require_dep = version_obj['suggest']
    PackagistCrawler.create_dependency require_dep, product, version_number, "suggest"
  end

  def self.create_dependency dependencies, product, version_number, scope
    return nil if dependencies.nil? || dependencies.empty?
    dependencies.each do |dep|
      require_name = dep[0]
      require_version = dep[1]
      if require_version.strip.eql?("self.version")
        require_version = version_number
      end
      dep_prod_key = require_name
      dep = Dependency.find_by( Product::A_LANGUAGE_PHP, product.prod_key, version_number, require_name, require_version, dep_prod_key )
      next if dep

      dependency = Dependency.new({:name => require_name, :version => require_version,
        :dep_prod_key => dep_prod_key, :prod_key => product.prod_key,
        :prod_version => version_number, :scope => scope, :prod_type => Project::A_TYPE_COMPOSER,
        :language => Product::A_LANGUAGE_PHP })
      dependency.save
      dependency.update_known
      self.logger.info " ---- Create new dependency: #{dependency.prod_key}:#{dependency.prod_version} depends on #{dependency.dep_prod_key}:#{dependency.version}"
    end
  end

  def self.create_developers authors, product, version_number
    if authors && !authors.empty?
      authors.each do |author|
        author_name     = author['name']
        author_email    = author['email']
        author_homepage = author['homepage']
        author_role     = author['role']
        devs = Developer.find_by Product::A_LANGUAGE_PHP, product.prod_key, version_number, author_name
        next if devs && !devs.empty?

        developer = Developer.new({:language => Product::A_LANGUAGE_PHP,
          :prod_key => product.prod_key, :version => version_number,
          :name => author_name, :email => author_email,
          :homepage => author_homepage, :role => author_role})
        developer.save
      end
    end
  end

  def self.create_license( product, version_number, version_obj )
    license = version_obj['license']
    return nil if license.nil? || license.empty?
    license.each do |license_name|
      license_obj = License.new({ :language => product.language, :prod_key => product.prod_key,
        :version => version_number, :name => license_name })
      license_obj.save
    end
  end

  def self.crawle_object
    crawl = Crawle.new()
    crawl.crawler_name = "PackagistCrawler"
    crawl.crawler_version = "0.1.0"
    crawl.repository_src = "http://packagist.org/"
    crawl.start_point = "/"
    crawl.exec_group = Time.now.strftime("%Y-%m-%d-%I-%M")
    crawl.save
    return crawl
  end

  def self.store_error( crawl, subject, message, source )
    error = ErrorMessage.new({:subject => "#{subject}", :errormessage => "#{message}", :source => "#{source}", :crawle_id => crawl.id })
    error.save
  rescue => e
    self.logger.error "ERROR in store_error: #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end

end
