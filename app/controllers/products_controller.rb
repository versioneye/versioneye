class ProductsController < ApplicationController

  @@languages = ["Java", "Ruby", "Python", "Node.JS", "R", "JavaScript", "PHP", "Clojure"]

  def index
    @hide = "hide"
    @lang = cookies[:veye_lang]
    if @lang.nil?
      @lang = ""
      cookies[:veye_lang] = ""
    end
    @comments = Versioncomment.all().desc(:created_at).limit(10) 
    @newest = Array.new
    newest_ids = Array.new
    @hotest = Product.get_hotest(7)
    new_stuff = Newest.get_newest(200)
    if !new_stuff.nil? && !new_stuff.empty?
      new_stuff.each do |entry|
        product = entry.product
        if !product.nil? && !newest_ids.include?(product.id)
          @newest << product
          newest_ids << product.id
        end  
        break if @newest.size == 7
      end
    end
    @languages = @@languages # Product.get_unique_languages
    if signed_in?
      @my_product_ids = current_user.fetch_my_product_ids
    end
    render :layout => 'application_lp'
  end
  
  def search
    @query = params[:q]
    @lang = get_lang_value( params, cookies )
    commit = params[:commit]
    @query = do_replacements(@query, commit)
    if @query.length == 1
      flash.now[:error] = "Search term is to short. Please type in at least 2 characters."
    elsif @query.include?("%")
      flash.now[:error] = "the character % is not allowed"
    else
      languages = @lang.split(",")
      @products = Product.find_by_name(@query, languages, 300).paginate(:page => params[:page])
      if @products.nil? || @products.length == 0
        flash.now[:notice] = "Sorry. No Results found."
      else
        @my_product_ids = current_user.fetch_my_product_ids if signed_in?
      end
    end    
    respond_to do |format|
      format.html { 
        @languages = @@languages # Product.get_unique_languages 
      }
      format.json { render :json => @products }
    end
  end

  def autocomplete_product_name
    lang = get_lang_value( params, cookies )
    languages = lang.split(",")
    @products = Product.find_by_name(params[:term], languages, 10).paginate(:page => 1)
    respond_to do |format|
      format.json { render :json => @products.as_json(:only => [:name]) }
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
    if signed_in? 
      @productlike = fetch_productlike(current_user, @product)
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
    version_param = params[:version]
    ver = url_param_to_origin(version_param)
    attach_version( @product, ver )
    @comments = Versioncomment.find_by_prod_key_and_version(@product.prod_key, @product.version)
    @version = @product.get_version(@product.version)
    @downloads = @version.versionarchive
    @productlook = Productlook.find_by_key(key)
    @main_dependencies = @product.dependencies(nil)

    respond_to do |format|
      format.html { 
        if !mobile.nil? && mobile.eql?('true')
          render "show_mobile", :layout => "application_mobile"
        else
          @users = Array.new
          user_ids = Follower.find_followers_for_product( @product.id )
          @users = User.find_by_ids(user_ids)
          @versioncomment = Versioncomment.new 
          @versioncommentreply = Versioncommentreply.new
        end          
        }
      format.json { render :json => @product.as_json( {:following => following} ) }
    end
  end

  def show_visual
    key = url_param_to_origin params[:key]
    @product = Product.find_by_key( key )
    if @product.nil? 
      flash[:error] = "The requested package is not available."
      redirect_to products_path
      return 
    end
    ver = url_param_to_origin params[:version]
    attach_version @product, ver
    @version = @product.get_version(@product.version)
    @main_dependencies = @product.dependencies(nil)
    render :layout => 'application_visual'
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

  def recursive_dependencies
    key = url_param_to_origin params[:key]
    version = url_param_to_origin params[:version]
    product = Product.find_by_key( key )
    if !version.nil? && !version.empty?
      product.version = version  
    end
    @circle = product.dependency_circle(nil)
    respond_to do |format|
      format.json { 
        resp = ""
        @circle.each do |key, dep| 
          resp += "{"
          resp += "\"connections\": [#{dep.connections_as_string}],"
          resp += "\"text\": \"#{dep.text}\","
          resp += "\"id\": \"#{dep.id}\"," 
          resp += "\"version\": \"#{dep.version}\"" 
          resp += "},"
        end
        end_point = resp.length - 2
        resp = resp[0..end_point]
        render :json => "[#{resp}]"
      }
    end
  end

  def get_image_path
    image_key = params[:key]
    image_version = params[:version]
    url = get_s3_url("#{image_key}:#{image_version}.png")
    respond_to do |format|
      format.json { 
        if url_exist?(url)
          render :json => "#{url}"
        else
          render :json => "nil"
        end
      }
    end
  end

  def upload_image
    image_bin = params[:image]
    image_key = params[:key]
    image_version = params[:version]
    filename = "#{image_key}:#{image_version}.png"
    image_bin.gsub!(/data:image\/png;base64,/, "")
      AWS::S3::S3Object.store(
      filename, 
      Base64.decode64(image_bin), 
      Settings.s3_infographics_bucket, 
      :access => "public-read")
    url = get_s3_url(filename)
    respond_to do |format|
      format.json { 
        render :json => "#{url}"
      }
    end
  end
  
  private
    
    def do_replacements( query , commit="Commit" )
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

    def get_lang_value( params, cookies )
      lang = params[:lang]
      if lang.nil? || lang.empty? 
        lang = cookies[:veye_lang]
      else 
        cookies[:veye_lang] = { :value => lang, :expires => 24.hour.from_now }
      end
      lang
    end

    def get_s3_url filename
      url = AWS::S3::S3Object.url_for(filename, Settings.s3_infographics_bucket, :authenticated => false)
      url
    end

    def url_exist?(url_path)
      url = URI.parse(url_path)
      req = Net::HTTP.new(url.host, url.port)
      res = req.request_head(url.path)
      p "#{res.code}"
      if res.code == "200"
        return true
      else
        return false
      end
    end

end