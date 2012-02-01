module ProductsHelper
  
  def product_version_path(product)
    "/product/#{product.to_param}/version/#{product.version_to_url_param}/#{product.get_decimal_version_uid}"
  end
  
end