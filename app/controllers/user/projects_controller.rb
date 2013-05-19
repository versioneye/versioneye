class User::ProjectsController < ApplicationController

  before_filter :authenticate, :except => [:show, :badge]

  def index
    @project = Project.new
    @projects = Project.find_by_user(current_user.id.to_s)
  end

  def new
    @page = "project_new"
    @project = Project.new
  end

  def create
    file = params[:upload]
    project_url = nil
    if params[:project]
      project_url = params[:project][:url]
    end
    github_project = params[:github_project]

    if file && !file.empty?
      project = upload_and_store file
    elsif project_url && !project_url.empty?
      project = fetch_and_store project_url
    elsif github_project && !github_project.empty? && !github_project.eql?("NO_PROJECTS_FOUND")
      project = fetch_from_github_and_store github_project
      return nil if project.nil?
    else
      flash[:error] = "Please put in a URL OR select a file from your computer. Or select a GitHub project."
      redirect_to new_user_project_path
      return nil
    end
    respond_to do |format|
      format.html {
        if project and project.id
          redirect_to user_project_path( project._id )
        else
          redirect_to user_projects_path
        end
      }
      format.json {
        if project and project.id
          response_msg = {
            success: true,
            data: {project_id: project.id}
          }
        else
          response_msg = {
            success: false,
            msg: "Cant read project's info from Github or we have problems with s3."
          }
        end
        render json: response_msg
      }
    end
  rescue => e
    logger.error e
    e.backtrace.each do |message|
      logger.error message
    end
    flash[:error] = "VersionEye is not able to parse your project. Please contact the VersionEye Team."
    redirect_to user_projects_path
  end

  def show
    id = params[:id]
    @project = Project.find_by_id(id)
    if @project && @project.public == false
      return if authenticate == false
      redirect_to(root_path) unless current_user?(@project.user)
    end
  end

  def badge
    id = params[:id]
    @project = Project.find_by_id(id)
    path = "app/assets/images/badges"
    badge = "unknown"
    unless @project.nil?
      if @project.outdated?
        badge = "out-of-date"
      else
        badge = "up-to-date"
      end
    end
    send_file "#{path}/version_#{badge}.png", :type => "images/png", :disposition => 'inline'
  end

  def update
    file = params[:upload]
    project_id = params[:project_id]
    if file.nil? || project_id.nil?
      flash[:error] = "Something went wrong. Please contact the VersionEye Team."
      redirect_to user_projects_path
      return
    end
    project = Project.find_by_id project_id
    if project.nil?
      flash[:error] = "No project with given key. Please contact the VersionEye Team."
      redirect_to user_projects_path
      return
    end
    new_project = upload file
    if new_project.nil?
      flash[:error] = "Something went wrong. Please contact the VersionEye Team."
      redirect_to user_projects_path
    end

    project.update_from new_project
    flash[:success] = "ReUpload was successful."
    redirect_to user_project_path( project )
  end

  def destroy
    id = params[:id]
    ProjectService.destroy_project id
    respond_to do |format|
      format.html {redirect_to user_projects_path}
      format.json {
        render json: {success: true, project_id: id}}
    end
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
    ProjectService.process_project( @project )
    flash[:info] = "Project re parse is done."
    redirect_to user_project_path(@project)
  end

  def libs_i_follow
    @products = current_user.products.paginate(:page => params[:page])
  end

  def github_repositories
    respond_to do |format|
      format.html {
        @repos = Github.user_repos(current_user.github_token)
        if @repos && @repos['message'].nil?
          @repos.sort_by! {|repo| "%s" % repo["language"].to_s }
          @imported_repos = Project.by_user(current_user).by_source(Project::A_SOURCE_GITHUB)
          @imported_repo_names  = @imported_repos.map(&:name).to_set
          @supported_langs = Github.supported_languages
          @page = "project_new"
        else
          flash[:error] = "An error occured. Maybe you have to reconnect your VersionEye Account with your GitHub Account."
          redirect_to user_projects_path
        end
      }
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

  def save_visibility
    id = params[:id]
    visibility = params[:visibility]
    @project = Project.find_by_id(id)
    if visibility.eql? "public"
      @project.public = true
    else
      @project.public = false
    end
    @project.save
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

    def upload_and_store file
      project = upload file
      store_project project
      project
    end

    def upload file
      project_name = file['datafile'].original_filename
      filename = S3.upload_fileupload( file )
      url = S3.url_for( filename )
      project = create_project( url, project_name )
      project.s3_filename = filename
      project.source = Project::A_SOURCE_UPLOAD
      project
    end

    def fetch_and_store project_url
      project_name = project_url.split("/").last
      project = create_project( project_url, project_name )
      project.source = Project::A_SOURCE_URL
      store_project project
      project
    end

    def fetch_from_github_and_store github_project
      private_project = Github.private_repo?( current_user.github_token, github_project )
      if private_project && !is_allowed_to_add_private_project?
        flash[:error] = "You selected a private project. Please upgrade your plan to monitor the selected project."
        redirect_to settings_plans_path
        return nil
      end
      sha = Github.get_repo_sha( github_project, current_user.github_token )
      project_info = Github.get_project_info( github_project, sha, current_user.github_token )
      if project_info.empty?
        flash[:error] = "We couldn't find any project file in the selected project. Please choose another project."
        redirect_to new_user_project_path
        return nil
      end
      file = Github.fetch_file( project_info['url'], current_user.github_token )
      s3_infos = S3.upload_github_file( file, project_info['name'] )
      project = create_project(s3_infos['s3_url'], github_project)
      project.source = Project::A_SOURCE_GITHUB
      project.s3_filename = s3_infos['filename']
      project.github_project = github_project
      project.private_project = private_project
      store_project( project )
      project
    end

    def create_project( url, project_name )
      project = ProjectService.create_from_url( url )
      project.user_id = current_user.id.to_s
      if project.name.nil? || project.name.empty?
        project.name = project_name
      end
      project
    end

    def store_project(project)
      project.make_project_key!
      if project.dependencies && !project.dependencies.empty? && project.save
        project.save_dependencies
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
