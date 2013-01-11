class Api::V1::ProductsController < ApplicationController

  def ping
    respond_to do |format|
      format.json {
        render :json => {:success => true, :msg=>"Ping", :data => "pong"}
      }
    end
  end

  def search
    @query = do_parse_search_input( params[:id] )
    @groupid = params[:g]
    @lang = get_lang_value( params[:lang] )

    error = nil
    if ( (@query.nil? || @query.empty?) && (@groupid.nil? || @groupid.empty?) )
      error = "Please give us some input. Type in a value for name."
    elsif @query.length == 1
      error = "Search term is to short. Please type in at least 2 characters."
    elsif @query.include?("%")
      error = "the character % is not allowed"
    else
      start = Time.now
      languages = get_language_array(@lang)
      @products = ProductService.search(@query, @groupid, languages, params[:page])
      save_search_log( @query, @products, start )
    end
    respond_to do |format|
      format.json {
        if error
          render :json => {:success => false, :msg => error}
        else
          render :json => {:success => true,
                           :msg => "OK",
                           :data => JSON.parse(@products.to_json(
                                    :only => [:name, :version, :prod_key, 
                                              :group_id, :artifact_id, :language]))
                          } 
        end
      }
    end
  end

  def show
    key = url_param_to_origin params[:id]
    product = Product.find_by_key( key )
    if product.nil? 
      product = Product.find_by_key_case_insensitiv( key )  
    end
    respond_to do |format|
      format.json {
        if product.nil?
          render :json => {:success => true, :msg => "0 Results", :data => []}
        else
          render :json => {:success => true,
                           :msg => "N results",
                           :data => JSON.parse(product.to_json(
                             :only => [:name, :version, :prod_key, 
                                        :group_id, :artifact_id, :language, 
                                        :prod_type, :description, :link, :license ]))
                          }
        end
      }
    end
  end

  def languages
    if params.has_key? :lang
      language_string = params[:lang]
    else
      language_string = Product.all.distinct(:language).join(",")
    end
    render :json => get_language_array(language_string)
  end

  def statistics
    stats = Rails.cache.read("lang_stat")
    if stats.nil? or stats.empty?
      stats = Product.get_language_stat
      Rails.cache.write("lang_stat", stats)
    end

    render :json => stats.sort {|a, b| b[1] <=> a[1]}
  end

  def follow
    product_key = url_param_to_origin params[:product_key]
    respond = ProductService.create_follower product_key, current_user
    respond_to do |format|
      format.json { render :json => ["#{respond}"] }
    end
  end
  
  def unfollow
    src_hidden = params[:src_hidden]
    product_key = url_param_to_origin params[:product_key]
    respond = ProductService.destroy_follower product_key, current_user
    respond_to do |format|
      format.json { render :json => ["#{respond}"] }
    end
  end

end
