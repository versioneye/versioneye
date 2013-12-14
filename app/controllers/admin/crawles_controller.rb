class Admin::CrawlesController < ApplicationController

  before_filter :admin_user

  def index
    @exec_groups = Crawle.all().distinct(:exec_group).reverse()
  end

  def group
    group = params[:group]
    @exec_groups = Crawle.all().distinct(:exec_group).reverse()
    @crawles = Crawle.where(exec_group: /#{group}/i).desc(:created_at)
    render 'index'
  end

  def show
    @crawle = Crawle.find(params['id'])
  end

  private

    def admin_user
      redirect_to(root_path) unless signed_in_admin?
    end

end
