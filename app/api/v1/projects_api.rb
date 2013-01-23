require 'grape'

require_relative 'helpers/project_helpers.rb'
require_relative 'helpers/session_helpers.rb'

require_relative 'entities/project_entity.rb'
require_relative 'entities/project_dependency_entity.rb'

module VersionEye
  class ProjectsApi < Grape::API
    helpers ProjectHelpers
    helpers SessionHelpers

    resource :projects do

      before do
        track_apikey
      end

      desc "show users projects" 
      get do
        authorized?
        @user_projects = Project.by_user(@current_user)
        present @user_projects, with: Entities::ProjectEntity
      end

      desc "show the project's information", {
        notes: %q[ It shows detailed info of your project. ]
      }
      params do 
        requires :project_key,  :type => String, 
                                :desc => "Project specific identificator"
      end
      get '/:project_key' do
        authorized?
        proj_key = params[:project_key]
        project = Project.by_user(@current_user).where(project_key: proj_key).shift 
        if project.nil?
          error! "Project `#{params[:id]}` dont exists", 400
        end
        project.fetch_dependencies
        present project, with: Entities::ProjectEntity,
                         type: :full
      end

      desc "upload project file"
      params do
        requires :upload, type: Hash, desc: "Project file - [maven.pom, Gemfile ...]"
      end
      post do
        authorized?
        if params[:upload].nil?
          error! "Didnt submit file or used wrong parameter.", 400
        end
        
        if params[:upload].is_a? String
          error! "File field is plain text. It should be multipart submition.", 400
        end

        datafile = ActionDispatch::Http::UploadedFile.new(params[:upload])
        project_file = {'datafile' => datafile}

        @project = upload_and_store(project_file)
        if @project.nil?
          error! "Cant save uploaded file. Probably our fileserver got cold.", 500
        end

        @project.fetch_dependencies
        present @project, with: Entities::ProjectEntity, :type => :full 
      end

      desc "delete given project"
      params do
        requires :project_key, :type => String, :desc => "Delete project file"
      end
      delete '/:project_key' do
        authorized?
        proj_key = params[:project_key]
        error!("Project key cant be empty", 400) if proj_key.nil? or proj_key.empty?


        project = Project.by_user(@current_user).where(project_key: proj_key).shift
        if project.nil? or not destroy_project(project.id)
          error! "Deletion failed because you dont have such project: #{proj_key}", 500
        end
        
        {success: true, message: "Project deleted successfully."}
      end

    end
  end
end
