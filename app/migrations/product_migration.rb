class ProductMigration

  def self.update_followers
    products = Product.where( :"user_ids.0" => {"$exists"=>true} )
    products.each do |product|
      product.followers = product.users.count
      product.save
      Rails.logger.info "update followers for #{product.name}"
    end
    Rails.logger.info "#{products.count} products updated."
  end

  def self.count_versions(lang)
    versions_count = 0
    count = Product.where(language: lang).count()
    Rails.logger.info "language: #{lang}, count: #{count}"
    pack = 100
    max = count / pack
    (0..max).each do |i|
      skip = i * pack
      products = Product.where(language: "Java").skip(skip).limit(pack)
      products.each do |product|
        versions_count = versions_count + product.versions.count
      end
    end
    versions_count
  end

  def self.update_name_downcase_global
    products = Product.where(name_downcase: nil)
    products.each do |product|
      product.name_downcase = String.new(product.name.downcase)
      product.save
    end
  end

  def self.update_meta_data_global
    count = Product.count()
    page = 100
    iterations = count / page
    iterations += 1
    (0..iterations).each do |i|
      skip = i * page
      products = Product.all().skip(skip).limit(page)
      products.each do |product|
        VersionService.update_version_data( product, true )
        product.update_used_by_count( true )
        self.update_followers( product )
      end
    end
  end

  def self.update_followers( product )
    return nil if product.followers == product.user_ids.count
    product.followers = product.user_ids.count
    product.save
  end

  def self.update_version_data_global
    count = Product.count()
    page = 100
    iterations = count / page
    iterations += 1
    (0..iterations).each do |i|
      skip = i * page
      products = Product.all().skip(skip).limit(page)
      products.each do |product|
        VersionService.update_version_data( product )
      end
    end
  end

  def self.parse_release_date_global(lang)
    Product.where(language: lang).each do |product|
      product.versions.each do |version|
        if version.released_string.nil?
          Rails.logger.info "empty!"
          next
        end
        version.released_at = DateTime.parse version.released_string
        version.save
        Rails.logger.info "#{version.released_at}"
      end
      product.save
    end
  end

  def self.remove_leading_vs(lang)
    Product.where(language: lang).each do |product|
      product.versions.each do |version|
        if version.version.match(/v[0-9]+\..*/)
          Rails.logger.info "#{version.version}"
          version.version = version.version.gsub("v", "")
          product.save
          Rails.logger.info " -- #{version.version}"
        end
      end
    end
  end

  def self.count_central_mvn_repo()
    count = 0
    Product.where(language: "Java").each do |product|
      product.repositories.each do |repo|
        if repo.src.eql?("http://search.maven.org/")
          count += 1
          Rails.logger.info "count #{count}"
        end
      end
    end
  end

  def self.remove_bad_links(lang)
    Product.where(language: lang).each do |product|
      product.http_links.each do |link|
        if link.link.match(/^http.*/).nil?
          Rails.logger.info "remove #{link.link}"
          link.remove
        end
      end
      product.save
    end
  end

  def self.improve_ruby_links()
    Product.where(language: "Ruby").each do |product|
      Versionlink.where(prod_key: product.prod_key).each do |link|
        if !link.version.nil?
          Rails.logger.info "improve link #{product.prod_key} - #{link.link} - #{link.version}"
          link.version = nil
          link.save
        end
      end
    end
  end

  def self.check_emtpy_release_dates(lang)
    Product.where(language: lang).each do |product|
      product.versions.each do |version|
        if version.released_string.nil?
          Rails.logger.info "#{product.name} - #{version.version} - empty!"
          next
        end
      end
    end
  end

  def self.xml_site_map
    Rails.logger.info "xml_site_map"
    uris = Array.new
    sitemap_count = 1
    count = Product.count()
    pack = 100
    max = count / pack
    (0..max).each do |i|
      skip = i * pack
      products = Product.all().skip(skip).limit(pack)
      products.each do |product|
        uri = "#{product.language_esc}/#{product.to_param}/#{product.version_to_url_param}"
        uris << uri
      end
      if uris.count > 49000
        Rails.logger.info "#{uris.count}"
        Rails.logger.info "sitemap count: #{sitemap_count}"
        write_to_xml(uris, "sitemap-#{sitemap_count}.xml")
        uris = Array.new
        sitemap_count += 1
      end
    end
    Rails.logger.info "#{uris.count}"
    Rails.logger.info "sitemap count: #{sitemap_count}"
    write_to_xml(uris, "sitemap-#{sitemap_count}.xml")
    return true
  end

  def self.write_to_xml(uris, name)
    Rails.logger.info "write to xml"
    xml = Builder::XmlMarkup.new( :indent => 2 )
    xml.instruct!(:xml, :encoding => "UTF8", :version => "1.0")
    xml.urlset(:xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9") do |urlset|
      uris.each do |uri|
        urlset.url do |url|
          url.loc "http://www.versioneye.com/#{uri}"
        end
      end
    end
    xml_data = xml.target!
    xml_file = File.open(name, "w")
    xml_file.write(xml_data)
    xml_file.close
  end

end
