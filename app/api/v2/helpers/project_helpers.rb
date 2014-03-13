
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
    project = ProjectService.upload file, current_user, true
    ProjectService.store project
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
