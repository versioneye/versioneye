module VersionEye
  module ProjectHelpers
     
    def file_attached?(file_obj)
      result = false
      
      if file_obj.nil? == false and file_obj.respond_to?(:original_filename) 
        result = true
      end

      return result
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
end
