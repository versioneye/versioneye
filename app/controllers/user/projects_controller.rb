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
    project_type = params[:project][:project_type]
    
    url = upload_to_s3 params
    project = Project.create_from_file(project_type, url)
        
    project.user_id = current_user.id.to_s
    project.name = project_name
    project.project_type = project_type
    project.url = url
    if !project.dependencies.nil? && !project.dependencies.empty? && project.save
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
  
    def upload_to_s3 ( params )
      fileUp = params[:upload]
      orig_filename =  fileUp['datafile'].original_filename
      fname = sanitize_filename(orig_filename)
      random = create_random_value
      filename = "#{random}_#{fname}"
      bucket = "#{configatron.s3_projects_bucket}"
      AWS::S3::S3Object.store(filename, fileUp['datafile'].read, bucket, :access => :public_read)
      url = AWS::S3::S3Object.url_for(filename, bucket, :authenticated => false)
      url
    end
  
    def sanitize_filename(file_name)
      just_filename = File.basename(file_name)
      just_filename.sub(/[^\w\.\-]/,'_')
    end
    
    def create_random_value
      chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
      value = ""
      20.times { value << chars[rand(chars.size)] }
      value
    end
  
end