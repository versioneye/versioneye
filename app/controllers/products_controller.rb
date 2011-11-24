class ProductsController < ApplicationController

  def index
    @product = Product.new
    @messageout = "home"
  end
  
  def search    
    @procuts = Product.where("name = ?", params[:q])
    @messageout = "search "
  end

end