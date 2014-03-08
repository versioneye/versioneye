class User::PackagesController < ApplicationController

  before_filter :authenticate
  before_filter :new_project_redirect, :only => [:popular_in_my_projects]

  def popular_in_my_projects
    @packages = {}
    projects = current_user.projects
    if projects && !projects.empty?
      projects.each do |project|
        project.dependencies.each do |dependency|
          key = dependency.name
          @packages[key] ||= []
          @packages[key] << project
        end
      end
    end
  end

  def i_follow
    @products = current_user.products.paginate(:page => params[:page])
    if @products.nil? || @products.empty?
      @popular_packages = Product.all().desc(:followers).limit(10)
    end
  end

end
