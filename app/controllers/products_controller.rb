class ProductsController < ApplicationController

  def index
    @hide = "hide"
    @lang = session[:lang]
    if @lang.nil?
      @lang = ""
      session[:lang] = ""
    end
    @comments = Versioncomment.all().desc(:created_at).limit(10) 
    @newest = Array.new
    newest_ids = Array.new
    @hotest = Product.get_hotest(10)
    new_stuff = Newest.get_newest(200)
    new_stuff.each do |entry|
      product = entry.product
      if !newest_ids.include? product.id
        @newest << product
        newest_ids << product.id
      end  
      break if @newest.size == 10    
    end
    @languages = Product.get_unique_languages
    if signed_in?
      @my_product_ids = current_user.fetch_my_product_ids
    end    
  end
  
  def search
    @query = params[:q]
    @lang = params[:lang]
    commit = params[:commit]
    @query = do_replacements(@query, commit)     
    if @lang.nil? || @lang.empty? 
      @lang = ""
    end
    session[:lang] = @lang
    if @query.length == 1
      flash.now[:error] = "Search term is to short. Please type in at least 2 characters."
    elsif @query.include?("%")
      flash.now[:error] = "the character % is not allowed"
    else
      languages = @lang.split(",")
      @products = Product.find_by_name(@query, languages).paginate(:page => params[:page])
      if @products.nil? || @products.length == 0
        flash.now[:notice] = "Sorry. No Results found."
      else
        @my_product_ids = current_user.fetch_my_product_ids if signed_in?
      end
    end    
    respond_to do |format|
      format.html { @languages = Product.get_unique_languages }
      format.json { render :json => @products }
    end
  end
  
  def show
    mobile = params[:mobile]
    key = url_param_to_origin params[:key]
    @product = Product.find_by_key( key )
    if @product.nil? 
      flash[:error] = "The requested package is not available."
      redirect_to products_path
      return 
    end
    following = false
    if (!current_user.nil?)
      @follower = Follower.find_by_user_id_and_product(current_user.id, @product._id.to_s)
      following = true if !@follower.nil?
      if !@follower.nil? && @follower.notification == true
        @follower.notification = false
        @follower.save
      end      
    end
    ver = url_param_to_origin params[:version]
    attach_version @product, ver
    @comments = Versioncomment.find_by_prod_key_and_version(@product.prod_key, @product.version)
    @version = @product.get_version(@product.version)
    @productlook = Productlook.find_by_key(key)
    respond_to do |format|
      format.html { 
        if !mobile.nil? && mobile.eql?('true')
          render "show_mobile", :layout => "application_mobile"
        else
          @users = Array.new
          user_ids = Follower.find_followers_for_product( @product.id )
          user_ids.each do |user_id|
            # TODO refactor this with one query
            @users << User.find_by_id(user_id)
          end
          @versioncomment = Versioncomment.new 
        end          
        }
      format.json { render :json => @product.as_json( {:following => following} ) }
    end
  end
  
  def follow
    product_key = url_param_to_origin params[:product_key]
    @product = fetch_product product_key
    @product.followers = @product.followers + 1
    @product.save
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
    @product.followers = @product.followers - 1
    @product.save
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
    version = url_param_to_origin params[:version]
    product = Product.find_by_key(key)
    result = true    
    if !product.nil? && !product.versions_empty?
      result = product.wouldbenewest?(version)
    end
    respond_to do |format|
      format.json { render :json => result.to_json }
    end
  end
  
  def biggest
    vers1 = params[:version1]
    vers2 = params[:version2]    
    version = Naturalsorter::Sorter.get_newest_version(vers1, vers2)
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
    
    def do_replacements( query , commit )
      if query.nil? || @query.empty? || @query.eql?("Be up-to-date")
        return "json"
      end
      if commit.eql?("Lucky")
        product = Product.random_product
        return product.name
      else
        query.strip
        q = query.gsub!(" ", "-")
        return q unless q.nil?
        return query if q.nil?
      end      
    end

end