module ProductsHelper
  
  def product_version_path(product)
    if product.nil? 
      "/package/0/version/0"
    else 
      "/package/#{product.to_param}/version/#{product.version_to_url_param}"
    end
  end
  
  def product_url(product)
    if product.nil? 
      "/package/0/"
    else 
      "/package/#{product.to_param}"
    end
  end
  
  def display_follow(product)
    if product.in_my_products
      "none"
    else
      "block"
    end
  end
  
  def display_unfollow(product)
    if product.in_my_products
      "block"
    else
      "none"
    end
  end
  
  def product_version_path_short(product)
    if product.nil?
      "/package/0/version/0/1"
    else
      "/package/#{product.to_param}/version/#{product.version_to_url_param}"
    end    
  end
  
  def attach_version(product, version, version_uid)
    if version.nil? || version.empty? 
      return nil
    end
    versionObj = product.get_version(version)
    if versionObj.nil?
      versionObj = product.get_version_by_uid(version_uid)
    end
    if !versionObj.nil?
      product.version = versionObj.version
      product.version_link = versionObj.link
      product.version_rate = versionObj.rate
    end
  end
  
end