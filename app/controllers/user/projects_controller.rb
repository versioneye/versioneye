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
    if project_name.nil? || project_name.empty? 
      flash[:error] = "The Name is mandatory. Please choose a name."
      redirect_to new_user_project_path
      return nil
    end

    file = params[:upload]
    project_url = params[:project][:url]
    github_project = params[:github_project]
    
    if file && !file.empty?
      filename = upload_to_s3( file )
      url = Project.get_project_url_from_s3( filename )
      project_type = get_project_type( url )
      project_type = "Maven2" if project_type.nil?
      project = create_project(project_type, url, project_name)
      project.s3_filename = filename
      project.s3 = true
      store_project(project)
    elsif project_url && !project_url.empty?
      project_type = get_project_type( project_url )
      project_type = "Maven2" if project_type.nil?
      project = create_project(project_type, project_url, project_name)
      project.s3 = false
      store_project(project)
    elsif github_project && !github_project.empty?
      sha = Project.get_repo_sha_from_github( github_project, current_user.github_token )
      project_info = Project.get_project_info_from_github( github_project, sha, current_user.github_token )
      if project_info.empty?
        flash[:error] = "We couldn't fine any project file in the selected project. Please choose another project."
        redirect_to new_user_project_path
        return nil    
      end
      s3_infos = Project.fetch_file_from_github(project_info['url'], current_user.github_token, project_info['name'])
      project = create_project(project_info['type'], s3_infos['s3_url'], project_name)
      project.s3 = true
      project.s3_filename = s3_infos['filename']
      project.github = true
      project.github_project = github_project
      store_project(project)
    else
      flash[:error] = "Please put in a URL OR select a file from your computer. Or select a GitHub project."
      redirect_to new_user_project_path
      return nil  
    end
    
    redirect_to user_projects_path
  end
  
  def destroy
    id = params[:id]
    project = Project.find_by_id(id)
    if project.s3 
      Project.delete_project_from_s3( project.s3_filename )
    end
    project.fetch_dependencies
    project.dependencies.each do |dep|
      dep.remove
    end
    project.remove
    redirect_to user_projects_path
  end

  def github_projects
    respond_to do |format|
      format.json { 
        resp = "{\"projects\": ["
        projects = JSON.parse HTTParty.get("https://api.github.com/user/repos?access_token=#{current_user.github_token}").response.body
        projects.each do |project|
          full_name = project['full_name']
          resp += "\"#{full_name}\","
        end
        end_point = resp.length - 2
        resp = resp[0..end_point]
        resp += "]}"
        render :json => "[#{resp}]"
      }
    end
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

    def create_project( project_type, url, project_name )
      project = Project.create_from_file( project_type, url )
      project.user_id = current_user.id.to_s
      project.name = project_name
      project.project_type = project_type
      project.url = url
      project
    end

    def store_project(project)
      if project.dependencies && !project.dependencies.empty? && project.save
        dependencies = Array.new(project.dependencies)
        Project.save_dependencies(project, dependencies)
        flash[:info] = "Project was created successfully."
      else
        flash[:error] = "Ups. An error occured. Something is wrong with your file. Please contact the VersionEye Team by using the Feedback button."
      end
    end
  
end