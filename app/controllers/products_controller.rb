class ProductsController < ApplicationController

  def index
    
  end
  
  def search    
    @products = Product.find_by_name(params[:q])
  end

end