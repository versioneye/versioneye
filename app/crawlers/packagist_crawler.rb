class PackagistCrawler

  def self.crawl
    packages = PackagistCrawler.get_first_level_list
    packages.each do |name|
      PackagistCrawler.crawle_package name
    end
  end

  def self.get_first_level_list
    body = JSON.parse HTTParty.get('http://packagist.org/packages/list.json' ).response.body
    body['packageNames']
  end

  def self.crawle_package name
    return nil if name.nil? || name.empty?
    p "crawle #{name}"
    resource = "http://packagist.org/packages/#{name}.json"
    pack = JSON.parse HTTParty.get( resource ).response.body
    package = pack['package']
    package_name = package['name']

    product = PackagistCrawler.get_product package_name
    PackagistCrawler.update_product product, package	

    packagist_page = "http://packagist.org/packages/#{package_name}"
    PackagistCrawler.update_packagist_link product, package_name

    package['versions'].each do |version|
      version_number = version[0]
      version_obj = version[1]
      db_version = product.get_version version_number
      if db_version.nil? 
        PackagistCrawler.create_new_version product, version_number, version_obj
      end
    end
  rescue => e 
    p "ERROR in crawle_package Message:   #{e.message}"
    p "ERROR in crawle_package backtrace: #{e.backtrace}"
  end

  def self.get_product name
    product = Product.find_by_key "php/#{name}"
    return product if product
    p " -- new product - #{name}"
    Product.new
  end

  def self.update_product product, package 
    name = package['name']
    product.prod_key = "php/#{name}"
    product.name = name
    product.description = package['description']
    product.prod_type = "Packagist"
    product.language = "PHP"
    product.save
  end

  def self.update_packagist_link product, packagist_page
    versionlink = Versionlink.find_by(product.prod_key, packagist_page)
    return nil if versionlink
    versionlink = Versionlink.new({:name => "Packagist Page", :link => packagist_page, :prod_key => product.prod_key})
    versionlink.save
  end

  def self.create_new_version product, version_number, version_obj
    db_version = Version.new
    db_version.version = version_number
    db_version.released_string = version_obj['time']
    db_version.released_at = DateTime.parse(version_obj['time'])
    license = version_obj['license']
    if license && !license.empty?
      db_version.license = license[0]  
    end
    product.versions.push db_version
    product.update_version_data
    product.save

    p " -- product: #{product.prod_key} -- version: #{version_number}"

    CrawlerUtils.create_newest product, version_number  
    CrawlerUtils.create_notifications product, version_number

    Versionlink.create_versionlink product.prod_key, version_number, version_obj['homepage'], "Homepage"

    PackagistCrawler.create_developers version_obj['authors'], product, version_number
    PackagistCrawler.create_download product, version_number, version_obj
    PackagistCrawler.create_dependencies product, version_number, version_obj
  rescue => e 
    p "ERROR in create_new_version Message:   #{e.message}"
    p "ERROR in create_new_version backtrace: #{e.backtrace}"
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
      dep_prod_key = "php/#{require_name}"
      dep = Dependency.find_by(require_name, require_version, dep_prod_key, product.prod_key, version_number)
      if dep.nil?
        dependency = Dependency.new({:name => require_name, :version => require_version, 
          :dep_prod_key => product.prod_key, :prod_key => "php/#{require_name}", 
          :prod_version => require_version, :scope => scope, :prod_type => "Packagist", 
          :language => "PHP"})
        dependency.save
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

end