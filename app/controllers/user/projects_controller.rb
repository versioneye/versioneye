class User::ProjectsController < ApplicationController

  before_filter :authenticate,  :except => [:show, :badge, :transitive_dependencies, :status, :lwl_export, :lwl_csv_export]
  before_filter :collaborator?, :only   => [:add_collaborator, :save_period, :save_visibility, :save_whitelist, :save_cwl, :update, :update_name, :destroy, :transfer, :team]
  before_filter :lwl_export_permission?, :only => [:lwl_export, :lwl_csv_export]


  def index
    @project  = Project.new

    filter = {}
    filter[:organisation] = params[:organisation]
    filter[:name]     = params[:name]
    filter[:language] = params[:language]
    filter[:language] = 'ALL' if filter[:language].to_s.empty?

    if Settings.instance.environment.eql?('enterprise') || signed_in_admin?
      default_scope = 'user'
      default_scope = 'all_public' if current_user.projects.empty?

      filter[:scope]    = params[:scope]
      filter[:scope]    = 'all_public'  if params[:all_public].to_s.eql?("true")
      filter[:scope]    = default_scope if filter[:scope].to_s.empty?
    else
      filter[:scope] = 'user'
    end

    @projects = ProjectService.index current_user, filter, params[:sort]
  end


  def new
    @project = Project.new
    @project.url = params[:url]
  end


  def upload
    @project = Project.new
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
    if @project.visible_for_user?(current_user) == false
      flash[:error] = "You have no access to this project!"
      return if !authenticate
      redirect_to(root_path) unless current_user?(@project.user)
    end
    if child_id.to_s.eql?('summary')
      @summary = ProjectService.summary id
    else
      @child   = ProjectService.find_child( id, child_id )
    end
    @child   = @project if @child.nil?
    @child   = add_dependency_classes( @child )
    @whitelists = LicenseWhitelistService.index( @project.organisation ) if @project.organisation
    @cwls     = ComponentWhitelistService.index( @project.organisation ) if @project.organisation
    if @project.user && @project.user.ids.eql?(current_user.ids)
      @orgas = OrganisationService.index( current_user, true )
    end
  end


  def lwl_export_all
    type         = params[:type].to_s.downcase
    type         = 'pdf' if type.to_s.empty?
    flatten      = params[:flatten]
    flatten      = true if flatten.to_s.empty?
    orga         = params[:orga]
    organisation = Organisation.where(:name => orga).first
    projects     = organisation.projects
    project_name = organisation.name
    date_string  = DateTime.now.strftime("%d_%m_%Y")
    lwl = nil
    cwl = nil
    lwl_default_id = LicenseWhitelistService.fetch_default_id organisation
    lwl = LicenseWhitelist.find(lwl_default_id) if lwl_default_id
    cwl_default_id = ComponentWhitelistService.fetch_default_id organisation
    cwl = ComponentWhitelist.find(cwl_default_id) if cwl_default_id
    if type.eql?('pdf')
      pdf = LwlPdfService.process_all projects, lwl, cwl, flatten
      send_data pdf, type: 'application/pdf', filename: "#{date_string}_#{project_name}.pdf"
    else
      csv = LwlCsvService.process_all projects, lwl, cwl, flatten
      send_data csv, type: 'text/csv', filename: "#{date_string}_#{project_name}.csv"
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = "ERROR: #{e.message}"
    redirect_to :back
  end


  def lwl_export
    id      = params[:id]
    project = ProjectService.find( id )
    date_string = DateTime.now.strftime("%d_%m_%Y")
    project_name = project.name.gsub("/", "-")
    pdf = LwlPdfService.process project, true, true
    send_data pdf, type: 'application/pdf', filename: "#{date_string}_#{project_name}.pdf"
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = "ERROR: #{e.message}"
    redirect_to :back
  end


  def lwl_csv_export
    id      = params[:id]
    project = ProjectService.find( id )
    date_string = DateTime.now.strftime("%d_%m_%Y")
    project_name = project.name.gsub("/", "-")
    csv = LwlCsvService.process project, true, true
    send_data csv, type: 'text/csv', filename: "#{date_string}_#{project_name}.csv"
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = "ERROR: #{e.message}"
    redirect_to :back
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
    style = ''
    style = "__#{params[:style]}" if !params[:style].to_s.empty?
    key = "#{id}#{style}"
    badge = BadgeService.badge_for key
    send_data badge.svg, :type => "image/svg+xml", :disposition => 'inline'
  rescue => e
    p e.message
    p e.backtrace
  end


  def update_name
    @name        = params[:name]
    if project_member?(@project, current_user)
      Auditlog.add current_user, "Project", @project.ids, "Changed project name from `#{@project.name}` to `#{@name}`"
      @project.name = @name
      @project.save
    end
    respond_to do |format|
      format.js
    end
  end


  def update
    file = params[:upload]
    if file.nil?
      flash[:error] = 'Something went wrong. Please contact the VersionEye Team.'
      redirect_to user_projects_path
      return
    end

    @project = ProjectUpdateService.update_from_upload @project, file, current_user, false
    if @project.nil?
      flash[:error] = 'Something went wrong. Please contact the VersionEye Team.'
      redirect_to user_projects_path
    end

    Rails.cache.delete( @project.id.to_s )
    flash[:success] = "ReUpload was successful."
    redirect_to user_project_path( @project )
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = "ERROR: #{e.message}"
    redirect_to user_projects_path
  end


  def add_collaborator
    project = @project
    url = "/user/projects/#{project.id.to_s}#tab-collaborators"

    collaborator_info = params[:collaborator]
    if collaborator_info[:username].to_s.empty?
      flash[:error] = "You have to type in a name or an email address!"
      redirect_to( url ) and return
    end

    ProjectCollaboratorService.add_new project, current_user, collaborator_info[:username]
    Auditlog.add current_user, "Project", @project.ids, "Added collaborator `#{collaborator_info[:username]}`"

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


  def status
    id = params[:id]
    respond_to do |format|
      format.json { render :json => {"status": ProjectUpdateService.status_for(id) } }
      format.text { render :text => ProjectUpdateService.status_for(id) }
    end
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
    period = params[:period]
    url = "/user/projects/#{@project.id.to_s}#tab-settings"
    old_period = @project.period
    @project.period = period
    if @project.save
      flash[:success] = "Status saved."
      Auditlog.add current_user, "Project", @project.ids, "Changed period from `#{old_period}` to `#{period}`"
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to url
  end


  def save_visibility
    visibility = params[:visibility]
    url = "/user/projects/#{@project.id.to_s}#tab-settings"
    old_visibility = @project.public
    if visibility.eql? "public"
      @project.public = true
    else
      @project.public = false
    end
    user = current_user
    free_plan = user.plan.nil? || user.plan.price.to_i == 0
    public_projects_count = Project.by_user(user).where(:public => false).count
    if @project.public == false && free_plan == true && Rails.env.enterprise? == false && public_projects_count > 1
      flash[:warning] = "To keep your project in private mode you need a paid plane. Please upgrade your subscription."
      url = settings_plans_path
    elsif @project.save
      flash[:success] = "We saved your changes."
      Auditlog.add current_user, "Project", @project.ids, "Changed visibility.public from `#{old_visibility}` to `#{@project.public}`"
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to url
  end


  def save_notify_after_api_update
    id     = params[:id]
    notify = params[:notify]
    @project = Project.find_by_id id
    old_notify_after_api_update = @project.notify_after_api_update
    url = "/user/projects/#{@project.id.to_s}#tab-settings"
    if notify.eql?('notify')
      @project.notify_after_api_update = true
    else
      @project.notify_after_api_update = false
    end
    if @project.save
      flash[:success] = "We saved your changes."
      Auditlog.add current_user, "Project", @project.ids, "Changed notify_after_api_update from `#{old_notify_after_api_update}` to `#{@project.notify_after_api_update}`"
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to url
  end


  def save_whitelist
    id        = params[:id]
    list_name = params[:whitelist]
    old_lwl_name = @project.license_whitelist_name
    if LicenseWhitelistService.update_project @project, @project.organisation, list_name
      flash[:success] = "We saved your changes."
      Auditlog.add current_user, "Project", @project.ids, "Changed License Whitelist from `#{old_lwl_name}` to `#{list_name}`"
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to "/user/projects/#{id}#tab-settings"
  rescue => e
    flash[:error] = "An error occured (#{e.message}). Please contact the VersionEye Team."
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
  end


  def save_cwl
    id        = params[:id]
    list_name = params[:whitelist]
    old_lwl_name = @project.component_whitelist_name
    if ComponentWhitelistService.update_project @project, @project.organisation, list_name
      flash[:success] = "We saved your changes."
      Auditlog.add current_user, "Project", @project.ids, "Changed Component Whitelist from `#{old_lwl_name}` to `#{list_name}`"
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to "/user/projects/#{id}#tab-settings"
  rescue => e
    flash[:error] = "An error occured (#{e.message}). Please contact the VersionEye Team."
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
  end


  def transfer
    id      = params[:id]
    orga_id = params[:orga_id]
    organisation = Organisation.find orga_id
    if @project.user && @project.user.ids.eql?(current_user.ids) &&
      organisation && OrganisationService.owner?( organisation, current_user )
      @project.organisation = organisation
      @project.teams = [organisation.owner_team]
      if @project.save
        flash[:success] = "Ownership of the project was transfered to #{organisation.name}."
        Auditlog.add current_user, "Project", @project.ids, "Ownership was transfered to organisation `#{organisation.name}`."
      end
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to "/user/projects/#{id}#tab-settings"
  rescue => e
    flash[:error] = "An error occured (#{e.message}). Please contact the VersionEye Team."
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
  end


  def team
    id        = params[:id]
    team_name = params[:team_name]
    organisation = @project.organisation
    if OrganisationService.owner?( organisation, current_user )
      team = organisation.team_by team_name
      @project.teams = [team]
      if @project.save
        flash[:success] = "Project is assigned to #{team_name}."
        Auditlog.add current_user, "Project", @project.ids, "Project was assigned to team `#{team_name}`."
      end
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to "/user/projects/#{id}#tab-settings"
  rescue => e
    flash[:error] = "An error occured (#{e.message}). Please contact the VersionEye Team."
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join('\n')
  end


  def mute_dependency
    project_id    = params[:id]
    dependency_id = params[:dependency_id]
    mute_message  = params[:mute_message]
    muted = ProjectdependencyService.mute! project_id, dependency_id, true, mute_message
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


    def lwl_export_permission?
      return true if Rails.env.enterprise? == true
      if current_user.plan.nil? || current_user.plan.price.to_i < 22
        flash[:warning] = "For the PDF/CSV export you need at least the 'Medium' plan. Please upgrade your subscription."
        redirect_to settings_plans_path
        false
      end
      return true
    end


    def collaborator?
      id = params[:id]
      id = params[:project_id] if id.to_s.empty?
      @project = Project.find_by_id id
      if @project.nil?
        flash[:error] = "The project you are looking for doesn't exist."
        redirect_to :back
        false
      end

      return true if project_member?( @project, current_user )

      flash[:error] = "Permission denied. You are not a collaborator of this project!"
      redirect_to :back
      false
    end


    def calculate_language project
      children = project.children
      return "#{project.language}_".downcase if children.nil? || children.empty?

      lang = project.language
      children.each do |child|
        if !child.language.eql?(lang)
          return ''
        end
      end
      "#{lang}_".downcase
    end

    def fetch_project( params )
      file        = params[:upload]
      project_url = params[:project][:url]  if params[:project]
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
      if (project_url.match(/\Ahttps\:\/\/github\.com/) && project_url.count("/") == 4) || (project_url.match(/\/\z/))
        flash[:error] = "Please put in the complete URL to the file, not just the directory."
        return
      end

      project_name   = project_url.split("/").last
      project_name   = project_name.split('?')[0]
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

end
