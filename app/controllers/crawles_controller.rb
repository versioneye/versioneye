class CrawlesController < ApplicationController

  def index
    if signed_in_admin?
      @exec_groups = Crawle.all().distinct(:exec_group).reverse()
    end
  end
  
  def group
    group = params[:group]
    if signed_in_admin?
      @exec_groups = Crawle.all().distinct(:exec_group).reverse()
      @crawles = Crawle.all(conditions: { exec_group: /#{group}/i }).desc(:created_at)
    end
    render "index"
  end
  
  def show
    @crawle = Crawle.find(params['id'])
  end

end