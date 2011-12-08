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
        flash.now[:notice] = "Sorry. No Results found."
      end
    end        
  end
  
  def show
    key = get_product_key params[:id]
    @product = Product.find_by_key( key )
  end
  
  def follow
    @product_name = params[:product_name]
    @product_key = get_product_key params[:product_key]
    @email = params[:email]
    p params[:product_key]
    p @product_key
    
    product = fetch_product @product_key
    unsigneduser = fetch_unsigneduser @email
    create_unsignedfollower product, unsigneduser    
    
    respond_to do |format|
      format.html { redirect_to :product }
      format.js
    end
  end
  
  private
  
    def get_product_key(param)
      p param
      if (param.nil? || param.empty?)
        return ""
      end
      key = String.new(param)
      key.gsub!("--","/")
      key.gsub!("~",".")
      key
    end
  
    def fetch_product(product_key)
      product = Product.find_by_key product_key
      if product.nil?
        @message = "error"
      end
      product
    end
    
    def fetch_unsigneduser(email)
      unsigneduser = Unsigneduser.find_by_email email
      if unsigneduser.nil?
        unsigneduser = Unsigneduser.new
        unsigneduser.email = email
        unsigneduser.save
      end
      unsigneduser
    end
    
    def create_unsignedfollower(product, unsigneduser)
      if product.nil? || unsigneduser.nil?
        return nil
      end
      unsignedfollower = Unsignedfollower.find_by_unsigneduser_id_and_product unsigneduser.id, product.id
      if unsignedfollower.nil?
        unsignedfollower = Unsignedfollower.new
        unsignedfollower.unsigneduser = unsigneduser
        unsignedfollower.product = product 
        unsignedfollower.save
      end
    end

end