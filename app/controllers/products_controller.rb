class ProductsController < ApplicationController

  def index
    
  end
  
  def search    
    @products = Product.find_by_name(params[:q])
  end
  
  def show
    key = String.new(params[:id])
    key.gsub!("--","/")
    key.gsub!("~",".")
    @product = Product.find_by_key( key )
  end

end