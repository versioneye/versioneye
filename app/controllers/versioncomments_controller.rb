class VersioncommentsController < ApplicationController
  
  def create
    @versioncomment = Versioncomment.new(params[:versioncomment])
    @versioncomment.user = current_user
    if @versioncomment.save      
      flash[:success] = "Comment saved!"
    else 
      flash[:error] = "Something went wrong"
    end    
    prod_key = @versioncomment.product_key
    ver = @versioncomment.version
    update_product_rate(prod_key, ver)
    product_key = Product.to_url_param prod_key
    version = Product.to_url_param ver
    redirect_to "/product/#{product_key}/version/#{version}"
  end
  
  private 
  
    def update_product_rate(prod_key, version)
      avg = Versioncomment.get_average_rate_by_prod_key_and_version(prod_key, version)
      avg = 10 if avg < 15 && avg > 0
      avg = 20 if avg < 25 && avg >= 15
      avg = 30 if avg < 35 && avg >= 25
      avg = 40 if avg < 45 && avg >= 35
      avg = 50 if avg >= 45      
      product = Product.find_by_key(prod_key)
      prod_version = product.get_version(version)
      prod_version.rate = avg
      prod_version.save      
      product.update_rate
      product.save
    end
  
end