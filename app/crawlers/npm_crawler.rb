class NpmCrawler


  def self.logger
    ActiveSupport::BufferedLogger.new('log/npm.log')
  end


  def self.crawl
    crawl = crawle_object
    packages = get_first_level_list
    packages.each do |name|
      crawle_package name, crawl
    end
    crawl.duration = Time.now - crawl.created_at
    crawl.save
    self.logger.info(" *** This crawle took #{crawl.duration} *** ")
    return nil
  end


  def self.get_first_level_list
    self.logger.info 'Start fetching first level list'
    packages = JSON.parse HTTParty.get('http://registry.npmjs.org/-/short' ).response.body
    self.logger.info ' -- done.'
    packages
  end


  def self.crawle_package name, crawl
    self.logger.info "crawl #{name}"
    prod_json = JSON.parse HTTParty.get("http://registry.npmjs.org/#{name}").response.body
    versions  = prod_json['versions']
    return nil if versions.nil? || versions.empty?

    prod_key  = prod_json['_id']
    prod_name = prod_json['name']
    time      = prod_json['time']

    product = init_product prod_key
    update_product product, prod_json

    npm_page = "https://npmjs.org/package/#{prod_key}"
    update_npm_link product, npm_page

    versions.each do |version|
      version_number = String.new(version[0])
      version_obj = version[1]
      if version_number && version_number.match(/v[0-9]+\..*/)
        version_number.gsub!('v', '')
      end

      db_version = product.version_by_number version_number
      next if db_version

      create_new_version product, version_number, version_obj, time, crawl
    end
    VersionService.update_version_data( product )
  rescue => e
    self.logger.error "ERROR in crawle_package Message: #{e.message}"
    self.logger.error e.backtrace.join('\n')
    store_error crawl, e.message, e.backtrace, name
  end


  def self.create_new_version product, version_number, version_obj, time, crawl
    version_db = Version.new({:version => version_number})
    parse_release_date( version_db, time )
    product.versions.push version_db
    product.reindex = true
    product.save

    self.logger.info " -- NPM Package: #{product.prod_key} -- with new version: #{version_number}"

    self.create_license( product, version_number, version_obj )

    CrawlerUtils.create_newest( product, version_number, logger )
    CrawlerUtils.create_notifications( product, version_number, logger )

    bugs_link = bugs_for version_obj
    Versionlink.create_versionlink product.language, product.prod_key, version_number, bugs_link, 'Bugs'
    repo_link = repository_for version_obj
    Versionlink.create_versionlink product.language, product.prod_key, version_number, repo_link, 'Repository'
    homepage_link = homepage_for version_obj
    Versionlink.create_versionlink product.language, product.prod_key, version_number, homepage_link, 'Homepage'

    create_author product, version_number, version_obj['author']
    create_maintainers product, version_number, version_obj['maintainers']

    create_download product, version_number, version_obj
    create_dependencies product, version_number, version_obj
  rescue => e
    self.logger.error "ERROR in create_new_version Message:   #{e.message}"
    self.logger.error e.backtrace.join("\n")
    store_error crawl, e.message, e.backtrace, product.name
  end


  def self.init_product name
    product = Product.find_by_lang_key( Product::A_LANGUAGE_NODEJS, name )
    return product if product
    self.logger.info " -- New Node.JS Package - #{name}"
    Product.new({:reindex => true})
  end


  def self.update_product product, package
    name                  = package['name']
    product.prod_key      = package['_id']
    product.name          = name
    product.name_downcase = name.downcase
    product.description   = package['description']
    product.prod_type     = Project::A_TYPE_NPM
    product.language      = Product::A_LANGUAGE_NODEJS
    product.save
  end


  def self.update_npm_link product, npm_page
    versionlink = Versionlink.find_by( Product::A_LANGUAGE_NODEJS, product.prod_key, npm_page )
    return nil if versionlink
    versionlink = Versionlink.new({:name => "NPM Page", :link => npm_page, :prod_key => product.prod_key, :language => Product::A_LANGUAGE_NODEJS })
    versionlink.save
  end


  def self.crawle_object
    crawl                 = Crawle.new
    crawl.crawler_name    = 'NpmCrawler'
    crawl.crawler_version = '0.1.0'
    crawl.repository_src  = 'http://registry.npmjs.org/'
    crawl.start_point     = '/'
    crawl.exec_group      = Time.now.strftime('%Y-%m-%d-%I-%M')
    crawl.save
    return crawl
  end


  def self.create_author product, version_number, author
    return nil if author.nil? || author.empty?

    author_name     = author['name']
    author_email    = author['email']
    author_homepage = author['homepage']
    author_role     = author['role']
    devs = Developer.find_by Product::A_LANGUAGE_NODEJS, product.prod_key, version_number, author_name
    return nil if devs && !devs.empty?

    developer = Developer.new({:language => Product::A_LANGUAGE_NODEJS,
      :prod_key => product.prod_key, :version => version_number,
      :name => author_name, :email => author_email,
      :homepage => author_homepage, :role => author_role})
    developer.save
  end


  def self.create_maintainers product, version_number, maintainers
    return nil if maintainers.nil? || maintainers.empty?

    maintainers.each do |author|
      create_author product, version_number, author
    end
  end


  def self.create_download product, version_number, version_obj
    dist = version_obj['dist']
    return nil if dist.nil? || dist.empty?
    dist_url  = dist['tarball']
    dist_name = dist_url.split("/").last
    archive = Versionarchive.new({:language => Product::A_LANGUAGE_NODEJS, :prod_key => product.prod_key,
      :version_id => version_number, :name => dist_name, :link => dist_url})
    Versionarchive.create_if_not_exist_by_name( archive )
  end


  def self.create_license( product, version_number, version_obj )
    license_name = version_obj['license']
    return nil if license_name.to_s.empty?

    product.version = version_number
    license_obj = License.for_product( product )
    return nil if license_obj

    self.logger.info " -- Node.JS Package - #{product} adding new license - #{license_name}"
    license_obj = License.new({ :language => product.language, :prod_key => product.prod_key,
      :version => version_number, :name => license_name })
    license_obj.save
  end


  def self.create_dependencies product, version_number, version_obj
    dependencies = version_obj['dependencies']
    create_dependency dependencies, product, version_number, Dependency::A_SCOPE_COMPILE

    devDependencies = version_obj['devDependencies']
    create_dependency devDependencies, product, version_number, Dependency::A_SCOPE_DEVELOPMENT

    bundledDependencies = version_obj['bundledDependencies']
    create_dependency bundledDependencies, product, version_number, Dependency::A_SCOPE_BUNDLED

    optionalDependencies = version_obj['optionalDependencies']
    create_dependency optionalDependencies, product, version_number, Dependency::A_SCOPE_OPTIONAL
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
      dep = Dependency.find_by( Product::A_LANGUAGE_NODEJS, product.prod_key, version_number, require_name, require_version, dep_prod_key )
      next if dep

      dependency = Dependency.new({:name => require_name, :version => require_version,
        :dep_prod_key => dep_prod_key, :prod_key => product.prod_key,
        :prod_version => version_number, :scope => scope, :prod_type => Project::A_TYPE_NPM,
        :language => Product::A_LANGUAGE_NODEJS })
      dependency.save
      dependency.update_known
      self.logger.info " ---- Create new dependency: #{dependency}"
    end
  end


  def self.bugs_for version_obj
    version_obj['bugs']['web']
  rescue => e
    nil
  end

  def self.repository_for version_obj
    version_obj['repository']['url']
  rescue => e
    nil
  end

  def self.homepage_for version_obj
    hp = version_obj['homepage']
    if hp.is_a? Array
      return hp.first
    end
    hp
  rescue => e
    logger.error "Error in homepage_for #{e.message}"
    logger.error e.backtrace.join('\n')
    nil
  end


  def self.parse_release_date version_db, time
    version_db.released_string = time[version_number]
    version_db.released_at     = DateTime.parse( version_db.released_string )
  rescue => e
    logger.error "Error in parse_release_date #{e.message}"
    logger.error e.backtrace.join('\n')
  end


  def self.store_error( crawl, subject, message, source )
    error = ErrorMessage.new({:subject => "#{subject}", :errormessage => "#{message}", :source => "#{source}", :crawle_id => crawl.id })
    error.save
  rescue => e
    self.logger.error "ERROR in store_error: #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


end
