module ProductsHelper
  
  def product_version_path(product)
    if product.nil? 
      "/product/0/version/0/0"
    else 
      "/product/#{product.to_param}/version/#{product.version_to_url_param}/#{product.get_decimal_version_uid}"
    end
  end
  
  def product_version_path_short(product)
    if product.nil?
      "/product/0/version/0/1"
    else
      "/product/#{product.to_param}/version/#{product.version_to_url_param}/1"
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