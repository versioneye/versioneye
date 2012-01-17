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
    product = Product.find_by_key(prod_key)    
    update_product_rate(product, ver)    
    redirect_to product_version_path(product)
  end
  
  private 
  
    def update_product_rate(product, ver)
      avg = Versioncomment.get_average_rate_by_prod_key_and_version(product.prod_key, ver)      
      version = product.get_version(ver)
      version.rate = Versioncomment.get_flatted_average(avg)
      version.ratecount = Versioncomment.get_count_by_prod_key_and_version(product.prod_key, ver)
      version.save      
      product.update_rate
      product.save
    end
  
end