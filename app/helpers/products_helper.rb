module ProductsHelper
  
  def product_version_path(product)
    return "/package/0/version" if product.nil? 
    return "/package/#{product.to_param}/version/#{product.version_to_url_param}"
  end
  
  def product_url(product)
    return "/package/0/" if product.nil? 
    return "/package/#{product.to_param}"
  end
  
  def display_follow(product)
    return "none" if product.in_my_products
    return "block"
  end
  
  def display_unfollow(product)
    return "block" if product.in_my_products
    return "none"
  end
  
  def create_follower(product, user)
    return nil if product.nil? || user.nil?
    follower = Follower.find_by_user_id_and_product user.id, product._id.to_s
    if follower.nil?
      follower = Follower.new
      follower.user_id = user._id.to_s
      follower.product_id = product._id.to_s
      follower.save
    end
    return "success"
  end
  
  def destroy_follower(product, user)
    return nil if product.nil? || user.nil?
    follower = Follower.find_by_user_id_and_product user._id.to_s, product._id.to_s
    if !follower.nil?
      follower.remove
    end
    return "success"
  end
  
  def attach_version(product, version_from_url)
    return nil if product.nil?
    version = url_param_to_origin( version_from_url )
    if version.nil? || version.empty?
      version = product.version
    end
    versionObj = product.get_version(version)
    if versionObj
      product.version = versionObj.version
      product.version_link = versionObj.link
      if versionObj.created_at
        today = DateTime.now.to_date
        diff = today - versionObj.created_at.to_date
        product.last_crawle_date = diff.to_i
      end
    end
  end

  def fetch_productlike(user, product)
    productlike = Productlike.find_by_user_id_and_product(user.id, product.prod_key)
    if productlike.nil?
      productlike = Productlike.new
      productlike.user_id = user.id.to_s 
      productlike.prod_key = product.prod_key
      productlike.save
    end
    productlike
  end

  def fetch_product(product_key)
    product = Product.find_by_key product_key
    if product.nil?
      @message = "error"
      flash.now[:error] = "An error occured. Please try again later."
    end
    product
  end

  def url_param_to_origin(param)
    if (param.nil? || param.empty?)
      return ""
    end
    key = String.new(param)
    key.gsub!("--","/")
    key.gsub!("~",".")
    key
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
        product.versions.each do |version|
          uri = "package/#{product.to_param}/version/#{version.to_url_param}"
          uris << uri
        end
      end
      if uris.count > 47000 
        p "#{uris.count}"
        p "sitemap count: #{sitemap_count}"
        write_to_xml(uris, "sitemap_#{sitemap_count}.xml")
        uris = Array.new
        sitemap_count += 1
      end
    end
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

  def do_parse_search_input( query , description, group_id)
    hash = Hash.new 
    query_empty = query.nil? || query.empty? || query.eql?("Be up-to-date")
    description_empty = description.nil? || description.empty? || description.length < 2
    group_id_empty = group_id.nil? || group_id.empty?
    if query_empty && description_empty && group_id_empty
      hash['query'] = "json"
      return hash
    end
    
    if (!query_empty)
      hash = Hash.new 
      hash['query'] = ""
      parts = query.split(" ")
      parts.each do |part| 
        if !part.match(/^g:/i).nil?
          hash['group'] = part.gsub("g:", "")
        elsif !part.match(/^d:/i).nil?
          hash['description'] = part.gsub("d:", "")
        else 
          hash['query'] += part + " "
        end
      end
      new_query = hash['query']
      new_query = new_query.strip()
      new_query.downcase!
      return hash
    end

    query = query.strip()
    hash['query'] = query.gsub(" ", "-")
    return hash
  end

  def generate_json_for_circle(circle)
    resp = ""
    circle.each do |key, dep| 
      resp += "{"
      resp += "\"connections\": [#{dep.connections_as_string}],"
      resp += "\"text\": \"#{dep.text}\","
      resp += "\"id\": \"#{dep.id}\"," 
      resp += "\"version\": \"#{dep.version}\"" 
      resp += "},"
    end
    end_point = resp.length - 2
    resp = resp[0..end_point]
    resp
  end
  
end