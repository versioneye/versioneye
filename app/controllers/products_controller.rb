class ProductsController < ApplicationController

  def index
    respond_to do |format|
      format.html { render :layout => "application_lean" }
    end
  end
  
  def search
    @query = params[:q]
    @query = @query.strip unless @query.nil?
    if @query.nil? || @query.empty? || @query.eql?("Be up-to-date")
      @query = "junit"
    end
    if @query.length == 1
      flash.now[:error] = "Search term is to short. Please type in at least 2 characters."
    elsif @query.include?("%")
      flash.now[:error] = "the character % is not allowed"
    else  
      @products = Product.find_by_name(@query).paginate(:page => params[:page])
      if @products.nil? || @products.length == 0
        flash.now[:notice] = "Sorry. No Results found."
      else
        if signed_in?
          @my_product_ids = current_user.fetch_my_product_ids
        end
      end
    end
    
    respond_to do |format|
      format.html 
      format.json { render :json => @products }
    end
  end
  
  def show
    mobile = params[:mobile]
    key = url_param_to_origin params[:key]
    @product = Product.find_by_key( key )
    following = false
    if (!current_user.nil?)
      @follower = Follower.find_by_user_id_and_product(current_user.id, @product._id.to_s)
      following = !@follower.nil?
    end
    version_uid = Product.decimal_to_hex( params[:uid] )
    ver = url_param_to_origin params[:version]
    attach_version @product, ver, version_uid
    @comments = Versioncomment.find_by_prod_key_and_version(@product.prod_key, @product.version)
    respond_to do |format|
      format.html { 
        if !mobile.nil? && mobile.eql?('true')
          render "show_mobile", :layout => "application_mobile"
        else
          @versioncomment = Versioncomment.new 
        end          
        }
      format.json { render :json => @product.as_json( {:following => following} ) }
    end
  end
  
  def follow
    product_key = url_param_to_origin params[:product_key]
    @product = fetch_product product_key
    respond = create_follower @product, current_user
    respond_to do |format|
      format.js
      format.html { 
          redirect_to product_version_path(@product)
        }
      format.json { render :json => "[#{respond}]" }
    end
  end
  
  def unfollow    
    src_hidden = params[:src_hidden]
    product_key = url_param_to_origin params[:product_key]    
    @product = fetch_product product_key
    respond = destroy_follower @product, current_user
    respond_to do |format|
      format.js 
      format.json { render :json => "[#{respond}]" }
      format.html { 
          if src_hidden.eql? "detail"
            redirect_to product_version_path(@product)
          else
            redirect_to user_path(current_user)
          end
        }
    end
  end
  
  private
  
    def url_param_to_origin(param)
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
    
    def create_follower(product, user)
      if product.nil? || user.nil?
        return nil
      end
      follower = Follower.find_by_user_id_and_product user.id, product._id.to_s
      if follower.nil?
        follower = Follower.new
        follower.user = user
        follower.product_id = product._id.to_s
        follower.save
      end
      return "success"
    end
    
    def destroy_follower(product, user)
      if product.nil? || user.nil?
        return nil
      end
      follower = Follower.find_by_user_id_and_product user.id, product._id.to_s
      if !follower.nil?
        follower.delete
      end
      return "success"
    end

end