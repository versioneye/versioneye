
module ProjectHelpers

  def file_attached?(file_obj)
    result = false

    if file_obj.nil? == false and file_obj.is_a?(ActionDispatch::Http::UploadedFile )
      result = true
    end

    result
  end

  def fetch_project_by_key_and_user(project_key, current_user)
    project = Project.by_user(current_user).where(project_key: project_key).shift
    if project.nil?
      project = Project.by_user(current_user).where(_id: project_key).shift
    end
    project
  end

  def destroy_project(project_id)
    project = Project.find_by_id(project_id)
    if project.s3_filename && !project.s3_filename.empty?
      S3.delete(project.s3_filename)
    end
    project.dependencies.each do |dep|
      dep.remove
    end
    project.remove
  end

  def upload_and_store file
    project = upload file
    ProjectService.store project
    project
  end

  def upload file
    project_name = file['datafile'].original_filename
    filename = S3.upload_fileupload(file )
    url = S3.url_for( filename )
    project_type = ProjectService.type_by_filename( url )
    project = create_project(project_type, url, project_name)
    project.make_project_key!
    project.s3_filename = filename
    project.source = Project::A_SOURCE_UPLOAD
    project.api_created = true
    project
  end

  def create_project( project_type, url, project_name )
    project = ProjectService.build_from_url( url )
    project.user = current_user
    if project.name.nil? || project.name.empty?
      project.name = project_name
    end
    project.project_type = project_type
    project.url = url
    project
  end

  def add_dependency_licences(project)
    return nil if project.nil?
    return project if project.dependencies.empty?

    project.dependencies.each do |dep|
      prod = dep.product
      if !prod.nil? and !dep.unknown?
        dep[:license] = prod.license_info
      else
        dep[:license] = 'unknown'
      end
    end
    project
  end
end
