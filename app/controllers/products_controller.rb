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
    
    respond_to do |format|
      format.html 
      format.json { render :json => @products }
    end
  end
  
  def show
    key = get_product_key params[:id]
    @product = Product.find_by_key( key )
    if (signed_in?)
      @follower = Follower.find_by_user_id_and_product(current_user.id, @product.id)
    end
    respond_to do |format|
      format.html 
      format.json { 
        render :json => @product.as_json
        }
    end
  end
  
  # Used in the guest area. without login.
  def follow_for_guest
    @product_name = params[:product_name]
    @product_key = get_product_key params[:product_key]
    @email = params[:email]
    
    @product = fetch_product @product_key
    unsigneduser = fetch_unsigneduser @email
    create_unsignedfollower @product, unsigneduser    
    
    respond_to do |format|
      format.html {
        flash[:info] = "Thank you. You are following now #{@product_name} and we will inform you about new versions." 
        redirect_to @product
        }
      format.js
    end
  end
  
  # Used in the login area. With login.
  def follow
    product_key = get_product_key params[:product_key]
    @product = fetch_product product_key
    respond = create_follower @product, get_user(params)
    respond_to do |format|
      format.js
      format.html { redirect_to product_path(@product) }
      format.json { render :json => "[#{respond}]" }
    end
  end
  
  def unfollow    
    src_hidden = params[:src_hidden]
    product_key = get_product_key params[:product_key]    
    @product = fetch_product product_key
    respond = destroy_follower @product, get_user(params)
    respond_to do |format|
      format.json { render :json => "[#{respond}]" }
      format.html { 
          if src_hidden.eql? "detail"
            redirect_to product_path(@product)
          else
            redirect_to user_path(current_user)
          end
        }
    end
  end
  
  private
  
    def get_user(params)
      email = params[:email]
      password = params[:password]
      user = User.authenticate(email, password)
      if (user.nil?)
        user = current_user
      end
      user
    end
  
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
        flash.now[:error] = "An error occured. Please try again later."
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
    
    def create_follower(product, user)
      if product.nil? || user.nil?
        return nil
      end
      follower = Follower.find_by_user_id_and_product user.id, product.id
      if follower.nil?
        p "create new follower"
        follower = Follower.new
        follower.user = user
        follower.product = product 
        follower.save
      end
      return "success"
    end
    
    def destroy_follower(product, user)
      if product.nil? || user.nil?
        return nil
      end
      follower = Follower.find_by_user_id_and_product user.id, product.id
      if !follower.nil?
        follower.delete
      end
      return "success"
    end

end