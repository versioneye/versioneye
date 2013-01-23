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
    file = params[:upload]
    project_url = params[:project][:url]
    github_project = params[:github_project]
    
    if file && !file.empty?
      project = upload_and_store file
    elsif project_url && !project_url.empty?
      fetch_and_store project_url
    elsif github_project && !github_project.empty? && !github_project.eql?("NO_PROJECTS_FOUND")
      private_project = Github.private_repo?( current_user.github_token, github_project )
      if private_project && !is_allowed_to_add_private_project?
        flash[:error] = "You selected a private project. Please upgrade your plan to monitor the selected project."
        redirect_to settings_plans_path
        return nil    
      end
      sha = Project.get_repo_sha_from_github( github_project, current_user.github_token )
      project_info = Project.get_project_info_from_github( github_project, sha, current_user.github_token )
      if project_info.empty?
        flash[:error] = "We couldn't find any project file in the selected project. Please choose another project."
        redirect_to new_user_project_path
        return nil    
      end
      s3_infos = Project.fetch_file_from_github(project_info['url'], current_user.github_token, project_info['name'])
      project = create_project(project_info['type'], s3_infos['s3_url'], github_project)
      project.source = "github"
      project.s3_filename = s3_infos['filename']
      project.github_project = github_project
      project.private_project = private_project
      store_project(project)
    else
      flash[:error] = "Please put in a URL OR select a file from your computer. Or select a GitHub project."
      redirect_to new_user_project_path
      return nil  
    end

    if project and project.id 
      redirect_to user_project_path( project._id )
    else
      redirect_to user_projects_path
    end
  end

  def show
    id = params[:id]
    @project = Project.find_by_id(id)
  end

  def update
    file = params[:upload]
    project_id = params[:project_id]
    if file.nil? || project_id.nil? 
      flash[:error] = "Something went wrong. Please try again later."
      redirect_to user_projects_path
    end
    project = upload_and_store file
    if project
      old_project = Project.find_by_id project_id 
      project.name = old_project.name
      if project.save
        destroy_project project_id
      end
      flash[:success] = "ReUpload was successful."
      redirect_to user_project_path( project )
    else 
      flash[:error] = "Something went wrong. Please try again later."
      redirect_to user_projects_path
    end
  end
  
  def destroy
    id = params[:id]
    destroy_project id 
    redirect_to user_projects_path
  end

  def update_name
    @name = params[:name]
    id = params[:id]
    project = Project.find_by_id(id)
    project.name = @name 
    project.save 
    respond_to do |format|
      format.js
    end
  end

  def reparse
    id = params[:id]
    @project = Project.find_by_id(id)
    Project.process_project( @project )
    flash[:info] = "Project re parse is done."
    redirect_to user_project_path(@project)
  end

  def github_projects
    respond_to do |format|
      format.json { 
        resp = "{\"projects\": [\""
        repos1 = Github.user_repo_names( current_user.github_token )
        repos2 = Github.orga_repo_names( current_user.github_token )
        repos = repos1 + repos2
        if repos && !repos.empty?
          resp += repos.join("\",\"")
        else 
          resp += "NO_PROJECTS_FOUND"
        end
        resp += "\"]}"
        render :json => "[#{resp}]"
      }
    end
  end

  def get_popular
    @project = Project.new
    @libs = {}
    projects = Project.find_by_user(current_user.id.to_s)
    if projects && !projects.empty?
      projects.each do |project|
        project.fetch_dependencies.each  do |dependency|
          key = dependency.name
          @libs[key] ||= []
          @libs[key] << project
        end
      end
    end

    respond_to do |format|
      format.html { render :template => "user/projects/show_popular" }
    end
  end

  def save_period
    id = params[:id]
    period = params[:period]
    @project = Project.find_by_id(id)
    @project.period = period
    if @project.save
      flash[:success] = "Status saved."
    else 
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to user_project_path(@project)
  end

  def save_email
    id = params[:id]
    email = params[:email]
    @project = Project.find_by_id(id)

    new_email = nil
    user = current_user
    user_email = user.get_email(email)
    new_email = user_email.email if user_email
    new_email = user.email unless user_email

    @project.email = new_email
    if @project.save
      flash[:success] = "Status saved."
    else 
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to user_project_path(@project)
  end

  private

    def destroy_project project_id 
      project = Project.find_by_id( project_id )
      if project.s3_filename && !project.s3_filename.empty?
        Project.delete_project_from_s3( project.s3_filename )
      end
      project.fetch_dependencies
      project.dependencies.each do |dep|
        dep.remove
      end
      project.remove
    end

    def upload_and_store file
      project_name = file['datafile'].original_filename
      filename = Project.upload_to_s3( file )
      url = Project.get_project_url_from_s3( filename )
      project_type = get_project_type( url )
      project_type = "Maven2" if project_type.nil?
      project = create_project(project_type, url, project_name)
      project.s3_filename = filename
      project.source = "upload"
      project.make_project_key!
      store_project(project)
      project
    end

    def fetch_and_store project_url 
      project_type = get_project_type( project_url )
      project_type = "Maven2" if project_type.nil?
      project_name = project_url.split("/").last
      project = create_project(project_type, project_url, project_name)
      project.source = "url"
      store_project(project)
      project
    end

    def create_project( project_type, url, project_name )
      project = Project.create_from_file( project_type, url )
      project.user_id = current_user.id.to_s
      if project.name.nil? || project.name.empty?
        project.name = project_name
      end
      project.project_type = project_type
      project.url = url
      project
    end

    def store_project(project)
      if project.dependencies && !project.dependencies.empty? && project.save
        dependencies = Array.new(project.dependencies)
        Project.save_dependencies(project, dependencies)
        flash[:success] = "Project was created successfully."
      else
        flash[:error] = "Ups. An error occured. Something is wrong with your file. Please contact the VersionEye Team by using the Feedback button."
      end
    end

    def is_allowed_to_add_private_project?
      user = current_user
      private_projects = Project.find_private_projects_by_user(user.id)
      plan = user.plan
      if plan.private_projects > private_projects.count
        return true
      else
        return false
      end
    end

end
