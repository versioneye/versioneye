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
    JSON.parse HTTParty.get('http://registry.npmjs.org/-/short' ).response.body
  end

  def self.crawle_package name
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

    # TODO parse versions !

  rescue => e
    self.logger.error "ERROR in crawle_package Message: #{e.message}"
    self.logger.error e.backtrace.join('\n')
    store_error crawl, e.message, e.backtrace, name
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
    crawl.crawler_name    = "NpmCrawler"
    crawl.crawler_version = "0.1.0"
    crawl.repository_src  = "http://registry.npmjs.org/"
    crawl.start_point     = "/"
    crawl.exec_group      = Time.now.strftime("%Y-%m-%d-%I-%M")
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
