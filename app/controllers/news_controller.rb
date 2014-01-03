class NewsController < ApplicationController

  before_filter :authenticate, :only => :mynews

  def news
    @comments = Versioncomment.all().desc(:created_at).paginate(:page => params[:page])
  end

end
