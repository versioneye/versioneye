class CrawlesController < ApplicationController

  def index
    if signed_in_admin?
      @crawles = Crawle.all().desc(:created_at).limit(20)    
    end
  end
  
  def show
    @crawle = Crawle.find(params['id'])
  end

end