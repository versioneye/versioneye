class NewsController < ApplicationController
  
  before_filter :authenticate

  def index
  	 prod_keys = Versioncomment.get_prod_keys_for_user(current_user.id)
  	 @comments = Versioncomment.find_by_prod_keys(prod_keys).paginate(:page => params[:page]) 
  end
  
end
