class PackagistCrawler

  def self.crawl
    crawl = self.crawle_object
    packages = PackagistCrawler.get_first_level_list
    packages.each do |name|
      PackagistCrawler.crawle_package name, crawl
    end
    crawl.duration = Time.now - crawl.created_at
    crawl.save
    return nil
  end

  def self.get_first_level_list
    body = JSON.parse HTTParty.get('http://packagist.org/packages/list.json' ).response.body
    body['packageNames']
  end

  def self.crawle_package name, crawl
    return nil if name.nil? || name.empty?
    Rails.logger.info "Crawle #{name}"

    resource = "http://packagist.org/packages/#{name}.json"
    pack = JSON.parse HTTParty.get( resource ).response.body
    package = pack['package']
    package_name = package['name']
    versions = package['versions']
    return nil if versions.nil? || versions.empty?

    product = PackagistCrawler.get_product package_name
    PackagistCrawler.update_product product, package

    packagist_page = "http://packagist.org/packages/#{package_name}"
    PackagistCrawler.update_packagist_link product, packagist_page

    versions.each do |version|
      version_number = String.new(version[0])
      version_obj = version[1]
      if version_number && version_number.match(/v[0-9]+\..*/)
        version_number.gsub!("v", "")
      end
      db_version = product.version_by_number version_number
      if db_version.nil?
        PackagistCrawler.create_new_version product, version_number, version_obj, crawl
      else
        PackagistCrawler.create_dependencies product, version_number, version_obj
      end
    end
  rescue => e
    Rails.logger.error "ERROR in crawle_package Message:   #{e.message}"
    Rails.logger.error "ERROR in crawle_package backtrace: #{e.backtrace.first}"
    PackagistCrawler.store_error crawl, e.message, e.backtrace, name
  end

  def self.get_product name
    product = Product.find_by_key "php/#{name}"
    return product if product
    Rails.logger.info " -- New Product - #{name}"
    product = Product.new
    product.reindex = true
    product
  end

  def self.update_product product, package
    name = package['name']
    product.prod_key = "php/#{name}"
    product.name = name
    product.name_downcase = name.downcase
    product.description = package['description']
    product.prod_type = Project::A_TYPE_COMPOSER
    product.language  = Product::A_LANGUAGE_PHP
    product.save
  end

  def self.update_packagist_link product, packagist_page
    versionlink = Versionlink.find_by(product.prod_key, packagist_page)
    return nil if versionlink
    versionlink = Versionlink.new({:name => "Packagist Page", :link => packagist_page, :prod_key => product.prod_key})
    versionlink.save
  end

  def self.create_new_version product, version_number, version_obj, crawl
    db_version = Version.new
    db_version.version = version_number
    db_version.released_string = version_obj['time']
    db_version.released_at = DateTime.parse(version_obj['time'])
    license = version_obj['license']
    if license && !license.empty?
      db_version.license = license[0]
    end
    product.versions.push db_version
    product.reindex = true
    product.save

    Rails.logger.info " -- Product: #{product.prod_key} -- Version: #{version_number}"

    VersionService.update_version_data( product )

    CrawlerUtils.create_newest product, version_number
    CrawlerUtils.create_notifications product, version_number

    Versionlink.create_versionlink product.prod_key, version_number, version_obj['homepage'], "Homepage"

    PackagistCrawler.create_developers version_obj['authors'], product, version_number
    PackagistCrawler.create_download product, version_number, version_obj
    PackagistCrawler.create_dependencies product, version_number, version_obj
  rescue => e
    Rails.logger.error "ERROR in create_new_version Message:   #{e.message}"
    Rails.logger.error "ERROR in create_new_version backtrace: #{e.backtrace}"
    PackagistCrawler.store_error crawl, e.message, e.backtrace, product.name
  end

  def self.create_download product, version_number, version_obj
    dist = version_obj['dist']
    if dist && !dist.empty?
      dist_url = dist['url']
      dist_type = dist['type']
      dist_name = "#{product.name}.#{dist_type}"
      Versionlink.create_versionlink product.prod_key, version_number, dist_url, dist_name
    end
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
      dep_prod_key = "php/#{require_name}"
      dep = Dependency.find_by(product.prod_key, version_number, require_name, require_version, dep_prod_key)
      if dep.nil?
        dependency = Dependency.new({:name => require_name, :version => require_version,
          :dep_prod_key => dep_prod_key, :prod_key => product.prod_key,
          :prod_version => version_number, :scope => scope, :prod_type => Project::A_TYPE_COMPOSER,
          :language => "PHP"})
        dependency.save
        dependency.update_known
        Rails.logger.info " -- Create new dependency: #{dependency.prod_key}:#{dependency.prod_version} -> #{dependency.dep_prod_key}:#{dependency.version}"
      end
    end
  end

  def self.create_developers authors, product, version_number
    if authors && !authors.empty?
      authors.each do |author|
        author_name = author['name']
        author_email = author['email']
        author_homepage = author['homepage']
        author_role = author['role']
        devs = Developer.find_by product.prod_key, version_number, author_name
        if devs && !devs.empty?
          next
        end
        developer = Developer.new({:prod_key => product.prod_key,
          :version => version_number, :name => author_name, :email => author_email,
          :homepage => author_homepage, :role => author_role})
        developer.save
      end
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
    Rails.logger.error "ERROR in store_error: #{e.message}"
    Rails.logger.error "ERROR in store_error: #{e.backtrace.first}"
  end

end
