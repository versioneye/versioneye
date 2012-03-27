class ProjectsController < ApplicationController
  
  @@BUCKET = "veye_prod_projects"
  
  def index
    @project = Project.new
    if signed_in?
      @projects = Project.find_by_user(current_user.id.to_s)
    end
  end
  
  def new
    @project = Project.new
  end
  
  def create
    fileUp = params[:upload]
    orig_filename =  fileUp['datafile'].original_filename
    fname = sanitize_filename(orig_filename)
    random = create_random_value
    filename = "#{random}_#{fname}"
    AWS::S3::S3Object.store(filename, fileUp['datafile'].read, @@BUCKET, :access => :public_read)
    url = AWS::S3::S3Object.url_for(filename, @@BUCKET, :authenticated => false)
    
    project = Project.create_from_pom_url(url)
    project.user_id = current_user.id.to_s
    project.name = params[:project][:name]
    project.url = url
    if project.save
      project.dependencies.each do |dep|
        p "dep: #{dep.project_id}"
        dep.project_id = project.id.to_s
        dep.user_id = current_user.id.to_s
        dep.save
      end
    end
    redirect_to projects_path
  end
  
  def show
    id = params[:id]
    @project = Project.find_by_id(id)
  end
  
  private 
  
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