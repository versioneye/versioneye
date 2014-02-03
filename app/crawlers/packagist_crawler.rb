class PackagistCrawler


  def self.logger
    ActiveSupport::BufferedLogger.new('log/packagist.log')
  end


  def self.crawl
    start_time = Time.now
    packages = PackagistCrawler.get_first_level_list
    packages.each do |name|
      PackagistCrawler.crawle_package name
    end
    duration = Time.now - start_time
    self.logger.info(" *** This crawl took #{duration} *** ")
    return nil
  end


  def self.get_first_level_list
    body = JSON.parse HTTParty.get('http://packagist.org/packages/list.json' ).response.body
    body['packageNames']
  end


  def self.crawle_package name
    return nil if name.nil? || name.empty?

    resource     = "http://packagist.org/packages/#{name}.json"
    pack         = JSON.parse HTTParty.get( resource ).response.body
    package      = pack['package']
    package_name = package['name']
    versions     = package['versions']
    return nil if versions.nil? || versions.empty?

    product = PackagistCrawler.init_product package_name
    PackagistCrawler.update_product product, package
    PackagistCrawler.update_packagist_link product, package_name

    versions.each do |version|
      self.process_version version, product
    end
    ProductService.update_version_data( product )
  rescue => e
    self.logger.error "ERROR in crawle_package Message:   #{e.message}"
    self.logger.error e.backtrace.join('\n')
  end


  def self.process_version version, product
    version_number = String.new(version[0])
    version_obj = version[1]
    if version_number && version_number.match(/v[0-9]+\..*/)
      version_number.gsub!('v', '')
    end
    db_version = product.version_by_number version_number
    if db_version.nil?
      PackagistCrawler.create_new_version( product, version_number, version_obj )
      return nil
    end
    if version_number.match(/^dev\-/)
      Dependency.remove_dependencies Product::A_LANGUAGE_PHP, product.prod_key, version_number
      create_dependencies product, version_number, version_obj
      Versionarchive.remove_archives Product::A_LANGUAGE_PHP, product.prod_key, version_number
      create_archive     product, version_number, version_obj
    end
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


  def self.update_packagist_link product, package_name
    packagist_page = "http://packagist.org/packages/#{package_name}"
    Versionlink.create_project_link( Product::A_LANGUAGE_PHP, product.prod_key, packagist_page, 'Packagist Page' )
  end


  def self.create_new_version product, version_number, version_obj
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
    self.create_archive product, version_number, version_obj
    self.create_dependencies product, version_number, version_obj
  rescue => e
    self.logger.error "ERROR in create_new_version Message:   #{e.message}"
    self.logger.error e.backtrace.join('\n')
  end


  def self.create_archive product, version_number, version_obj
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
    PackagistCrawler.create_dependency require_dep, product, version_number, 'require'

    require_dev = version_obj['require-dev']
    PackagistCrawler.create_dependency require_dev, product, version_number, 'require-dev'

    replace = version_obj['replace']
    PackagistCrawler.create_dependency replace, product, version_number, 'replace'

    suggest = version_obj['suggest']
    PackagistCrawler.create_dependency suggest, product, version_number, 'suggest'
  end


  def self.create_dependency dependencies, product, version_number, scope
    return nil if dependencies.nil? || dependencies.empty?
    dependencies.each do |dep|
      require_name    = dep[0]
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
    return nil if authors.nil? || authors.empty?

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


  def self.create_license( product, version_number, version_obj )
    license = version_obj['license']
    return nil if license.nil? || license.empty?
    license.each do |license_name|
      license_obj = License.new({ :language => product.language, :prod_key => product.prod_key,
        :version => version_number, :name => license_name })
      license_obj.save
    end
  end

end
