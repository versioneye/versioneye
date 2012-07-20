class User::ProjectsController < ApplicationController
  
  before_filter :authenticate
  
  def index
    @project = Project.new
    @projects = Project.find_by_user(current_user.id.to_s)
  end
  
  def new
    @project = Project.new
  end
  
  def create    
    project_name = params[:project][:name]
    project_url = params[:project][:url]
    file = params[:upload]
    
    if (file.nil? || file.empty?) && (project_url.nil? || project_url.empty?)
      flash[:error] = "Please put in a URL OR select a file from your computer."
      redirect_to new_user_project_path
      return nil
    end

    if project_name.nil? || project_name.empty? 
      flash[:error] = "The Name is mandatory. Please choose a name."
      redirect_to new_user_project_path
      return nil
    end
    
    filename = get_filename( params )
    url = get_url( project_url, filename )
    project_type = get_project_type( url )
    
    project = Project.create_from_file( project_type, url )
    project.user_id = current_user.id.to_s
    project.name = project_name
    project.project_type = project_type
    project.url = url
    
    add_s3_attributes( project, project_url, filename )
    
    if project.dependencies && !project.dependencies.empty? && project.save
      project.dependencies.each do |dep|
        dep.project_id = project.id.to_s
        dep.user_id = current_user.id.to_s
        dep.save
      end
      flash[:info] = "Project was created successfully."
    else
      flash[:error] = "Ups. An error occured. Something is wrong with your file. Please contact the VersionEye Team by using the Feedback button."
    end
    redirect_to user_projects_path
  end
  
  def destroy
    id = params[:id]
    project = Project.find_by_id(id)
    if project.s3 
      delete_from_s3 project.s3_filename
    end
    project.fetch_dependencies
    project.dependencies.each do |dep|
      dep.remove
    end
    project.remove
    redirect_to user_projects_path
  end

  def show
    id = params[:id]
    @project = Project.find_by_id(id)
  end
  
  def follow
    user = current_user
    id = params[:id]
    @project = Project.find_by_id(id)
    @project.fetch_dependencies
    @project.dependencies.each do |dep|
      product = Product.find_by_key(dep.prod_key)
      if !product.nil? 
        create_follower(product, user)
      end
    end
    flash[:success] = "We added all known packages from this project to your fav. packages."
    redirect_to user_project_path(@project)
  end
  
  def unfollow
    user = current_user
    id = params[:id]
    @project = Project.find_by_id(id)
    @project.fetch_dependencies
    @project.dependencies.each do |dep|
      product = Product.find_by_key(dep.prod_key)
      if !product.nil? 
        destroy_follower(product, user)
      end
    end
    flash[:success] = "We removed all known packages from this project from your fav. packages."
    redirect_to user_project_path(@project)
  end  

  private 

    def get_filename(params)
      project_url = params[:project][:url]
      file = params[:upload]
      filename = ""
      if project_url.nil? || project_url.empty?
        filename = upload_to_s3( params )
      else 
        filename = file['datafile'].original_filename
      end
      return filename
    end

    def get_url(project_url, filename)
      url = ""
      if project_url.nil? || project_url.empty?
        url = get_s3_url filename
      else 
        url = project_url  
      end
      return url
    end

    def add_s3_attributes(project, project_url, filename)
      if (project_url.nil? || project_url.empty?)
        project.s3_filename = filename
        project.s3 = true
      else 
        project.s3 = false
      end
    end
  
end