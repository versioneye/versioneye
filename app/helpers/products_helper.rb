module ProductsHelper
  
  def product_version_path(product)
    "/product/#{product.to_param}/version/#{product.version_to_url_param}"
  end
  
end