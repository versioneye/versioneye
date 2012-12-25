class ProductMigration

  def self.create_test_db
    User.all().each do |user|
      user.email = "12_#{user.email}_34"
      user.save
    end
    Product.all().each do |product|
      if !product.language.eql?("Java")
        product.remove
      end
    end
  end

	def self.correct_namespace
		products = Product.where(:prod_type => "Packagist" )
		products.each do |product|

			product.name = product.prod_key.gsub("php/", "")
			product.save

			deps = Dependency.all(conditions: { prod_key: product.prod_key } )
			deps.each do |dep|
				dep.name = dep.dep_prod_key.gsub("php/", "")
				dep.save
			end

		end
	end

	def self.update_name_downcase_global
		products = Product.where(name_downcase: nil)
		products.each do |product|
			product.name_downcase = String.new(product.name.downcase)
			product.save
		end
	end

	def self.update_version_data_global
		count = Product.count()
		pack = 100
		max = count / pack 
		(0..max).each do |i|
			skip = i * pack
			products = Product.all().skip(skip).limit(pack)
			products.each do |product|
				product.update_version_data
			end
		end
	end

	def self.parse_release_date_global(lang)
		Product.where(language: lang).each do |product|
			product.versions.each do |version|
				if version.released_string.nil? 
					p "empty!"
					next 
				end
				version.released_at = DateTime.parse version.released_string
				version.save
				p "#{version.released_at}"
			end
			product.save
		end
	end

	def self.remove_leading_vs(lang)
		Product.where(language: lang).each do |product|
			product.versions.each do |version|
				if version.version.match(/v[0-9]+\..*/)
					p "#{version.version}"
	        version.version = version.version.gsub("v", "")
	        product.save
	        p " -- #{version.version}"
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
          p "count #{count}"
        end 
      end
    end
  end

  def self.count_central_mvn_repo()
    count = 0
    Product.where(language: "Java").each do |product|
      product.all_dependencies.each do |dependency|
        if dependency.dep_prod_key.eql?("org.testng/testng")
          count += 1
          p "count #{count}"
        end 
      end
    end
    p "#{count}"
  end

	def self.remove_bad_links(lang)
		Product.where(language: lang).each do |product|
			product.get_links.each do |link|
				if link.link.match(/^http.*/).nil?
					p "remove #{link.link}"
					link.remove
				end
			end
			product.save
		end
	end
  
  def self.improve_ruby_links()
    Product.where(language: "Ruby").each do |product|
      Versionlink.all(conditions: { prod_key: product.prod_key }).each do |link| 
        if !link.version_id.nil?
          p "improve link #{product.prod_key} - #{link.link} - #{link.version_id}"
          link.version_id = nil 
          link.save
        end
      end
    end
  end

	def self.check_emtpy_release_dates(lang)
		Product.where(language: lang).each do |product|
			product.versions.each do |version|
				if version.released_string.nil? 
					p "#{product.name} - #{version.version} - empty!"
					next 
				end
			end
		end
	end

	def self.xml_site_map
    p "xml_site_map"
    uris = Array.new
    sitemap_count = 1
    count = Product.count()
    pack = 100
    max = count / pack
    (0..max).each do |i|
      skip = i * pack
      products = Product.all().skip(skip).limit(pack)
      products.each do |product|
        uri = "package/#{product.to_param}"
        uris << uri
      end
      if uris.count > 49000 
        p "#{uris.count}"
        p "sitemap count: #{sitemap_count}"
        write_to_xml(uris, "sitemap-#{sitemap_count}.xml")
        uris = Array.new
        sitemap_count += 1
      end
    end
    p "#{uris.count}"
    p "sitemap count: #{sitemap_count}"
    write_to_xml(uris, "sitemap-#{sitemap_count}.xml")
    return true
  end

  def self.write_to_xml(uris, name)
    p "write to xml"
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