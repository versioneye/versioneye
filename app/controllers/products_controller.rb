class ProductsController < ApplicationController

  def index
  end
  
  def search
    @query = params[:q]
    @query = do_replacements ( @query ) 
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
      following = true if !@follower.nil?
      if !@follower.nil? && @follower.notification == true
        @follower.notification = false
        @follower.save
      end      
    end
    version_uid = Product.decimal_to_hex( params[:uid] )
    ver = url_param_to_origin params[:version]
    attach_version @product, ver, version_uid
    @comments = Versioncomment.find_by_prod_key_and_version(@product.prod_key, @product.version)
    @version = @product.get_version(@product.version)
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
  
  def newest
    key = url_param_to_origin params[:key]
    type = params[:type]
    version = "0"
    product = Product.find_by_key(key)
    if !type.nil? && !type.empty?
      if type.eql?("natural")
        version = product.get_newest_version_by_natural_order
      end
    end
    respond_to do |format|
      format.json { render :json => version.to_json }
    end
  end

  def wouldbenewest
    key = url_param_to_origin params[:key]
    ver = url_param_to_origin params[:version]
    result = true
    product = Product.find_by_key(key)
    if !product.nil? 
      version = product.get_newest_version_by_natural_order
      newest_version = get_newest(version, ver)
      if newest_version.eql?(ver)
        result = true
      else 
        result = false
      end
    end
    respond_to do |format|
      format.json { render :json => result.to_json }
    end
  end
  
  def biggest
    vers1 = params[:version1]
    vers2 = params[:version2]    
    version = get_newest(vers1, vers2)
    respond_to do |format|
      format.json { render :json => version.to_json }
    end
  end  
  
  private
  
    def url_param_to_origin(param)
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
        follower.user_id = user._id.to_s
        follower.product_id = product._id.to_s
        follower.save
      end
      return "success"
    end
    
    def destroy_follower(product, user)
      if product.nil? || user.nil?
        return nil
      end
      follower = Follower.find_by_user_id_and_product user._id.to_s, product._id.to_s
      if !follower.nil?
        follower.remove
      end
      return "success"
    end
    
    def get_newest(vers1, vers2)
      product = Product.new
      product.versions = Array.new

      version1 = Version.new
      version1.version = vers1
      product.versions.push(version1)

      version2 = Version.new
      version2.version = vers2
      product.versions.push(version2)

      product.get_newest_version_by_natural_order
    end
    
    def do_replacements ( query )
      query.strip unless query.nil?
      q = query.gsub!(" ", "-")
      return q unless q.nil?
      return query if q.nil?
    end

end