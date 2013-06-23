class NewsController < ApplicationController

  before_filter :authenticate, :only => :mynews
  #before_filter :force_http

  def news
    @comments = Versioncomment.all().desc(:created_at).paginate(:page => params[:page])
  end

  def mynews
    prod_keys = Versioncomment.get_prod_keys_for_user(current_user.id)
    @comments = Versioncomment.find_by_prod_keys(prod_keys).paginate(:page => params[:page])
  end

  def hotnews
    packages = Product.get_hotest( 30 )
    keys = Array.new()
    packages.each do |pack|
      keys << pack.prod_key
    end
    @comments = Versioncomment.find_by_prod_keys( keys )
  end

end
