class ProductsController < ApplicationController

  def index
    
  end
  
  def search
    @query = params[:q]
    if @query.nil? || @query.empty?
      flash.now[:error] = "Search field is empty. Please type in a search term."
    elsif @query.length == 1
      flash.now[:error] = "Search term is to short. Please type in at least 2 characters."
    elsif @query.include?("%")
      flash.now[:error] = "the character % is not allowed"
    else  
      @products = Product.find_by_name(@query).paginate(:page => params[:page], :per_page => 30)
      if @products.nil? || @products.length == 0
        flash.now[:info] = "Sorry. No Results found."
      end
    end        
  end
  
  def show
    key = String.new(params[:id])
    key.gsub!("--","/")
    key.gsub!("~",".")
    @product = Product.find_by_key( key )
  end
  
  def follow
    
    respond_to do |format|
      format.html { redirect_to @prdouct }
      format.js
    end
  end

end