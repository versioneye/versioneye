class Api::ProjectsController < ApplicationController
  def index
    render :json => make_fail_message("Not implemented.")
  end 

  def create
    response_msg = nil
    project_file = {'datafile' => params[:upload]}

    unless file_attached?(project_file['datafile']) 
      response_msg =  make_fail_message("File was missing.")
      render :json => response_msg
      return 0
    end

    project = upload_and_store(project_file)
    
    if project.nil?
      response_msg = make_fail_message("Creating project failed.")
    else
      response_data = {:id => project.id.to_s}
      response_msg = make_success_message("Project created.", response_data)
    end

    render :json => response_msg
  end

  def show
    project = Project.find_by_id params[:id]

    if project.nil? 
        response_msg = make_fail_message("Project `#{params[:id]}` don exist.")
    else
        response_data = project #TODO: add field filtering
        response_msg = make_success_message("Project is checked.", response_data)
    end
    
    render :json => project
  end

  def show_dependencies
    response_data = []
    project = Project.find_by_id params[:project_id]

    if project.nil?
      response_msg = make_fail_message("Project `#{params[:project_id]}` dont exist.")
      render :json => response_msg
      return 0
    end

    Project.process_project(project)
    unless project.dependencies.nil?
      project.dependencies.each do |dep|
        dep_data = {
          :prod_key           => dep.prod_key,
          :name               => dep.name,
          :updated_at         => dep.updated_at,
          :version_current    => dep.version_current,
          :version_requested  => dep.version_requested,
          :outdated           => dep.outdated
        }
        response_data << dep_data     
      end
    end

    response_msg = make_success_message(
                    "Got #{response_data.count} project dependencies.",
                    response_data)
    render :json => response_msg 
  end

  def delete
    response_data = {:id => params[:id]}
    response_msg = make_fail_message("Cant delete file", response_data)

    if destroy_project(params[:id])
      response_msg = make_success_message("Fail is deleted.", response_data)
    end

    render :json => response_msg
  end

private
 
  def file_attached?(file_obj)
    result = false
    
    if file_obj.nil? == false and file_obj.respond_to?(:original_filename) 
      result = true
    end

    return result
  end

  def make_fail_message(message, data = nil)
    fail_message = {
      :success => false,
      :msg => message,
      :data => data
    }
    return fail_message
  end

  def make_success_message(message, data = nil)
    success_message = {
      :success => true,
      :msg => message,
      :data => data
    }

    return success_message
  end

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

  def upload_and_store(file)
    project_name = file['datafile'].original_filename
    filename = Project.upload_to_s3(file )
    url = Project.get_project_url_from_s3( filename )
    project_type = get_project_type(url)
    project_type = "Maven2" if project_type.nil?
    project = create_project(project_type, url, project_name)
    project.s3_filename = filename
    project.source = "upload"
    store_project(project)
    project
  end

  def create_project( project_type, url, project_name )
    project = Project.create_from_file( project_type, url )
    current_user = User.first
    project.user_id = current_user.id.to_s
    if project.name.nil? || project.name.empty?
      project.name = project_name
    end
    project.project_type = project_type
    project.url = url
    project
  end

  def store_project(project)
    success = false
    if project.dependencies && !project.dependencies.empty? && project.save
      dependencies = Array.new(project.dependencies)
      Project.save_dependencies(project, dependencies)
      success = true
    end

    return success
  end
end
