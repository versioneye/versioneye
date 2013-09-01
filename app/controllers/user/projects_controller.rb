class User::ProjectsController < ApplicationController

  before_filter :authenticate        , :except => [:show, :badge]
  before_filter :new_project_redirect, :only   => [:index]

  def index
    @project = Project.new
  end

  def new
    @project = Project.new
  end

  def create
    project = fetch_project params
    if project.nil?
      flash[:error] = "Please put in a URL OR select a file from your computer. Or select a GitHub project."
      redirect_to new_user_project_path
      return nil
    end
    if project and project.id
      redirect_to user_project_path( project._id )
    else
      flash[:error] = "Cant import that project from Github: unparseable project file or issues with filestorage. Please send issue to versioneye."
      redirect_to :back
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.first
    flash[:error] = "VersionEye is not able to parse your project. Please contact the VersionEye Team."
    redirect_to user_projects_path
  end

  def show
    id = params[:id]
    @project = Project.find_by_id( id )
    @collaborators = @project.collaborators

    unless @project.visible_for_user?(current_user)
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
    send_file "#{path}/dep_#{badge}.png", :type => "images/png", :disposition => 'inline'
  end

  def update_name
    @name        = params[:name]
    id           = params[:id]
    project      = Project.find_by_id(id)
    project.name = @name
    project.save
    respond_to do |format|
      format.js
    end
  end

  def update
    file       = params[:upload]
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

  def add_collaborator
    collaborator_info = params[:collaborator]
    project = Project.find_by_id params[:id]

    if project.nil?
      flash[:error] = "Failure: Cant add collaborator - wrong project id."
      redirect_to :back and return
    end

    user = User.find_by_username(collaborator_info[:username])

    new_collaborator = ProjectCollaborator.new project_id: project[:_id].to_s,
                                               caller_id: current_user[:_id].to_s,
                                               owner_id: project[:user_id].to_s

    if user.nil?
      # activate invitation
      new_collaborator[:invitation_email] = collaborator_info[:username]
      new_collaborator[:invitation_code] = UserService.create_random_token
    else
      # add to collaborator
      new_collaborator[:active]  = true
      new_collaborator[:user_id] = user[:_id].to_s
    end

    unless new_collaborator.save
      flash[:error] = "Failure: cant add new collaborator - #{new_collaborator.errors.full_messages.to_sentence}"
      redirect_to :back and return
    end

    project.collaborators << new_collaborator
    UserMailer.new_collaboration(new_collaborator).deliver if new_collaborator[:active]

    flash[:success] = "We added a new collaborator to the project."
    redirect_to :back
  end

  def reparse
    id = params[:id]
    project = Project.find_by_id( id )
    ProjectService.update( project )
    flash[:info] = "Project re parse is done."
    redirect_to user_project_path( project )
  end

  def destroy
    id = params[:id]
    success = false
    msg = ""
    if Project.where(_id: id).exists?
      ProjectService.destroy id
      success = true
    else
      msg = "Cant remove project with id: `#{id}` - it doesnt exist. Please refresh page."
      Rails.logger.error msg
    end
    respond_to do |format|
      format.html {redirect_to user_projects_path}
      format.json {
        render json: {success: success, project_id: id, msg: msg}}
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
    id       = params[:id]
    email    = params[:email]
    @project = Project.find_by_id(id)

    new_email  = nil
    user       = current_user
    user_email = user.get_email(email)
    new_email  = user_email.email if user_email
    new_email  = user.email unless user_email

    @project.email = new_email
    if @project.save
      flash[:success] = "Status saved."
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to user_project_path(@project)
  end

  private

    def fetch_project( params )
      file        = params[:upload]
      project_url = nil
      if params[:project]
        project_url = params[:project][:url]
      end
      return upload_and_store( file )       if file && !file.empty?
      return fetch_and_store( project_url ) if project_url && !project_url.empty?
      return nil
    end

    def upload_and_store file
      project = upload file
      store_project project
      project
    end

    def upload file
      project_name        = file['datafile'].original_filename
      filename            = S3.upload_fileupload( file )
      url                 = S3.url_for( filename )
      project             = build_project( url, project_name )
      project.s3_filename = filename
      project.source      = Project::A_SOURCE_UPLOAD
      project
    end

    def fetch_and_store project_url
      project_name   = project_url.split("/").last
      project        = build_project( project_url, project_name )
      project.source = Project::A_SOURCE_URL
      store_project project
      project
    end

    def build_project( url, project_name )
      project      = ProjectService.build_from_url( url )
      project.user = current_user
      if project.name.nil? || project.name.empty?
        project.name = project_name
      end
      project
    end

    def store_project( project )
      if ProjectService.store project
        flash[:success] = "Project was created successfully."
      else
        flash[:error] = "Ups. An error occured. Something is wrong with your file. Please contact the VersionEye Team by using the Feedback button."
      end
    end

end
