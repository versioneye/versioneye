class User::ProjectsController < ApplicationController

  before_filter :authenticate        , :except => [:show, :badge, :transitive_dependencies]
  before_filter :new_project_redirect, :only   => [:index]


  def index
    all_public = params[:all_public]
    @project = Project.new
    if all_public
      @projects = Project.where(:public => true, :parent_id => nil).desc(:out_number_sum, :unknown_number_sum).asc(:name)
    else 
      @projects = Project.where(:user_id => current_user.id.to_s, :parent_id => nil).desc(:out_number_sum, :unknown_number_sum).asc(:name)
    end
  end


  def new
    @project = Project.new(params)
  end


  def upload
    @project = Project.new(params)
  end


  # Create a new project from file upload or URL. 
  def create
    project = fetch_project params
    if project.nil?
      flash[:error] = 'Please put in a URL OR select a file from your computer.' if flash[:error].nil?
      redirect_to new_user_project_path
    elsif project and project.id
      redirect_to user_project_path( project._id )
    else
      flash[:error] = "Can't import that project: unparseable project file or issues with filestorage. Please contact the VersionEye team."
      redirect_to :back
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = "ERROR: #{e.message}"
    redirect_to :back
  end


  def show
    id       = params[:id]
    child_id = params[:child]
    @project = ProjectService.find( id )
    @child   = ProjectService.find_child( id, child_id )
    @child   = @project if @child.nil? 
    @child   = add_dependency_classes( @child )
    if !@project.visible_for_user?(current_user)
      flash[:error] = "You have no access to this project!"      
      return if !authenticate
      redirect_to(root_path) unless current_user?(@project.user)
    end
    @whitelists = LicenseWhitelistService.index( current_user ) if current_user
  end


  def lwl_export
    id      = params[:id]
    project = ProjectService.find( id )
    date_string = DateTime.now.strftime("%d_%m_%Y")
    project_name = project.name.gsub("/", "-")
    pdf = LwlPdfService.process project
    send_data pdf, type: 'application/pdf', filename: "#{date_string}_#{project_name}.pdf"
  end


  def visual
    @project = ProjectService.find( params[:id] )
    render :layout => 'application_visual'
  end


  def transitive_dependencies
    id       = params[:id]
    @project = Project.find_by_id( id )
    hash = circle_hash_for_dependencies @project
    @products = Array.new
    circle = CircleElementService.fetch_deps(1, hash, Hash.new, @project.language)
    circle.each do |dep|
      next if dep.last[:level] == 0

      product = Product.fetch_product( @project.language, dep.last['dep_prod_key'] )
      next if product.nil?

      version = dep.last['version']
      if !version.to_s.empty? && !version.to_s.eql?('unknown')
        product.version = version
      end
      @products << product
    end
    respond_to do |format|
      format.js
    end
  end


  # send_file "#{path}/dep_#{badge}.png", :type => 'image/png', :disposition => 'inline'
  def badge
    id    = params[:id]
    project = Project.find id 
    badge = ProjectService.badge_for_project id
    path  = 'app/assets/images/badges'
    par = ""
    if params[:style]
      par = "?style=#{params[:style]}"
    end
    badge    = badge.gsub("-", "_")
    color    = badge.eql?('up_to_date') ? 'green' : 'yellow'
    language = calculate_language project
    url = "http://img.shields.io/badge/#{language}dependencies-#{badge}-#{color}.svg#{par}"
    response = HttpService.fetch_response url
    send_data response.body, :type => "image/svg+xml", :disposition => 'inline'
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
      flash[:error] = 'Something went wrong. Please contact the VersionEye Team.'
      redirect_to user_projects_path
      return
    end

    project = Project.find_by_id project_id
    if project.nil?
      flash[:error] = 'No project with given key. Please contact the VersionEye Team.'
      redirect_to user_projects_path
      return
    end

    project = ProjectUpdateService.update_from_upload project, file, current_user, false
    if project.nil?
      flash[:error] = 'Something went wrong. Please contact the VersionEye Team.'
      redirect_to user_projects_path
    end

    Rails.cache.delete( project.id.to_s )
    flash[:success] = "ReUpload was successful."
    redirect_to user_project_path( project )
  end


  def add_collaborator
    project = Project.find_by_id params[:id]

    if project.nil?
      flash[:error] = "Failure: Can't add collaborator - wrong project id."
      redirect_to :back and return
    end

    url = "/user/projects/#{project.id.to_s}#tab-collaborators"
    if !project.collaborator?( current_user )
      flash[:error] = "Permission denied. You are not a collaborator of this project!"
      redirect_to( url ) and return
    end
    
    collaborator_info = params[:collaborator]
    if collaborator_info[:username].to_s.empty?
      flash[:error] = "You have to type in a name or an email address!"
      redirect_to( url ) and return
    end

    ProjectCollaboratorService.add_new project, current_user, collaborator_info[:username] 

    flash[:success] = "We added a new collaborator to the project."
    redirect_to( url )
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = "ERROR: #{e.message}"
    redirect_to :back
  end


  def reparse
    id = params[:id]
    project = Project.find_by_id id
    ProjectUpdateService.update_async project 
    flash[:success] = "A background process was started to reparse the project. This can take a couple seconds."
    redirect_to user_project_path( project )
  end


  def followall
    id = params[:id]
    project = Project.find_by_id id
    project.dependencies.each do |dep|
      ProductService.follow dep.language, dep.prod_key, current_user
    end
    flash[:success] = "You follow now all packages from this project."
    redirect_to :back 
  end


  def destroy
    id = params[:id] 
    if ProjectService.destroy_by current_user, id
      flash[:success] = "Project removed successfully."
    else 
      flash[:success] = "Something went wrong. Please contact the VersionEye Team."
    end
    redirect_to user_projects_path
  rescue => e 
    flash[:error] = "ERROR: #{e.message}"
    redirect_to :back
  end


  def merge 
    child_id  = params[:id] 
    parent_id = params[:parent]
    if ProjectService.merge(parent_id, child_id, current_user.id) 
      flash[:success] = "Project merged successfully."
    else 
      flash[:success] = "Something went wrong. Merge not possible."
    end
    redirect_to "/user/projects/#{parent_id}"
  rescue => e 
    flash[:error] = "ERROR: (#{e.message})."
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
  end


  def unmerge 
    id = params[:id] 
    child_id = params[:child]
    if ProjectService.unmerge(id, child_id, current_user.id) 
      flash[:success] = "Project unmerged successfully."
    else 
      flash[:success] = "Something went wrong. Unmerge not possible."
    end
    redirect_to :back 
  rescue => e 
    flash[:error] = "ERROR: (#{e.message})."
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
  end


  def save_period
    id = params[:id]
    period = params[:period]
    @project = Project.find_by_id( id )
    url = "/user/projects/#{@project.id.to_s}#tab-settings"
    @project.period = period
    if @project.save
      flash[:success] = "Status saved." 
      update_collaborators @project 
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to url 
  end


  def save_visibility
    id = params[:id]
    visibility = params[:visibility]
    @project = Project.find_by_id(id)
    url = "/user/projects/#{@project.id.to_s}#tab-settings"
    if visibility.eql? "public"
      @project.public = true
    else
      @project.public = false
    end
    if @project.save
      flash[:success] = "We saved your changes."
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to url
  end


  def save_email
    id       = params[:id]
    email    = params[:email]
    @project = Project.find_by_id(id)
    url = "/user/projects/#{@project.id.to_s}#tab-settings"
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
    redirect_to url 
  end


  def save_notify_after_api_update
    id     = params[:id]
    notify = params[:notify]
    @project = Project.find_by_id id
    url = "/user/projects/#{@project.id.to_s}#tab-settings"
    if notify.eql?('notify')
      @project.notify_after_api_update = true
    else
      @project.notify_after_api_update = false
    end
    if @project.save
      flash[:success] = "We saved your changes."
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to url
  end


  def save_whitelist
    id        = params[:id]
    list_name = params[:whitelist]
    project  = Project.find_by_id id
    if LicenseWhitelistService.update_project project, current_user, list_name
      flash[:success] = "We saved your changes."
    else 
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to "/user/projects/#{id}#tab-licenses"
  rescue => e 
    flash[:error] = "An error occured (#{e.message}). Please contact the VersionEye Team."
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
  end


  def mute_dependency
    project_id    = params[:id]
    dependency_id = params[:dependency_id]
    muted = ProjectdependencyService.mute! project_id, dependency_id, true
    dependency = Projectdependency.find_by_id dependency_id
    render json: {"dependency_id" => dependency_id, "outdated" => dependency.outdated, "muted" => muted}
  end


  def demute_dependency
    project_id    = params[:id]
    dependency_id = params[:dependency_id]
    muted = ProjectdependencyService.mute! project_id, dependency_id, false
    dependency = Projectdependency.find_by_id dependency_id
    render json: {"dependency_id" => dependency_id, "outdated" => dependency.outdated, "muted" => muted}
  end


  private


    def calculate_language project
      children = project.children  
      return "#{project.language}_" if children.nil? || children.empty? 
      
      lang = project.language
      children.each do |child| 
        if !child.language.eql?(lang)
          return ''
        end
      end
      "#{lang}_"
    end

    def fetch_project( params )
      file        = params[:upload]
      project_url = params[:project][:url] if params[:project]
      return upload_and_store( file )       if file && !file.empty?
      return fetch_and_store( project_url ) if project_url && !project_url.empty?
      nil
    end

    def upload_and_store file
      project = ProjectImportService.import_from_upload file, current_user
      set_message_for project
      project
    end

    def fetch_and_store project_url
      project_name   = project_url.split("/").last
      project        = ProjectImportService.import_from_url( project_url, project_name, current_user )
      set_message_for project
      project
    end

    def set_message_for( project )
      if project
        flash[:success] = "Project was created successfully."
      else
        flash[:error] = "An error occured. Something is wrong with your file. Please contact the VersionEye Team on Twitter."
      end
    end

    def circle_hash_for_dependencies( project )
      hash = Hash.new
      project.dependencies.each do |dep|
        element = CircleElement.new
        element.init_arrays
        element.dep_prod_key = dep.prod_key
        element.version      = dep.version_requested
        element.level        = 0
        hash[dep.prod_key] = element
      end
      hash
    end

    def update_collaborators project 
      return nil if project.collaborators.nil? || project.collaborators.empty? 
      project.collaborators.each do |collaborator| 
        collaborator.period = project.period
        collaborator.save 
      end  
    end

end
