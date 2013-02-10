module VersionEye
  module ProjectHelpers
     
    def file_attached?(file_obj)
      result = false
      
      if file_obj.nil? == false and file_obj.is_a?(ActionDispatch::Http::UploadedFile ) 
        result = true
      end

      return result
    end

    def destroy_project project_id 
      project = Project.find_by_id( project_id )
      if project.s3_filename && !project.s3_filename.empty?
        S3.delete( project.s3_filename )
      end
      project.fetch_dependencies
      project.dependencies.each do |dep|
        dep.remove
      end
      project.remove
    end

    def upload_and_store(file)
      project_name = file['datafile'].original_filename
      filename = S3.upload_fileupload(file )
      url = S3.url_for( filename )
      
      project_type = Project.type_by_filename( url )
      project = create_project(project_type, url, project_name)
      project.make_project_key!      
      project.s3_filename = filename
      project.source = Project::A_SOURCE_UPLOAD
      store_project(project)
      
      project
    end

    # TODO remove the project_type parameter
    def create_project( project_type, url, project_name )
      project = ProjectService.create_from_url( url )
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
        project.save_dependencies( dependencies )
        success = true
      end
      return success
    end

  end
end
