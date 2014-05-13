class ServicesController < ApplicationController

  before_filter :check_refer, :only => [:index]

  def index
    @project = Project.new
  end

  def create
    file = params[:upload]

    if file.nil? || file.empty?
      flash[:error] = 'No file selected. Please select a project file from your computer.'
      redirect_to '/'
      return nil
    end

    project = ProjectImportService.import_from_upload file
    project.name = Project.create_random_value

    redirect_to service_path( project.id )
  rescue => e
    logger.error "ERROR Message:   #{e.message}"
    logger.error e.backtrace.join("\n")
    flash[:error] = 'Ups. An error occured. Something is wrong with your file. Please contact the VersionEye team.'
    redirect_to '/'
  end

  def show
    id       = params[:id]
    project  = Project.find_by_id( id )
    @project = add_dependency_classes( project )
  end

  def pricing
    @plan = current_user.plan if signed_in?
  end

  def choose_plan
    plan = params[:plan]
    cookies.permanent.signed[:plan_selected] = plan
    redirect_to signup_path
  end

end
