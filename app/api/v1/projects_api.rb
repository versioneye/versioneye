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

      desc "show project information"
      params do 
        requires :id, :type => String, :desc => "Project id"
      end
      get '/:id' do
        authorized?

        project = Project.find_by_id params[:id]
        if project.nil?
          error! "Project `#{params[:id]}` dont exists", 400
        end

        present project, with: Entities::ProjectEntity
      end

      desc "upload project file"
      params do
        requires :upload, :desc => "Project file"
      end
      post do
        authorized?

        if params[:upload].nil?
          error! "Didnt submit file or used wrong parameter.", 400
        end
        datafile = ActionDispatch::Http::UploadedFile.new(params[:upload])
        project_file = {'datafile' => datafile}


        project = upload_and_store(project_file)
        if project.nil?
          error! "Cant save uploaded file. Probably our fileserver got cold.", 500
        end
        
        present project, with: Entities::ProjectEntity
      end

      desc "delete given project"
      params do
        requires :id, :type => String, :desc => "Delete project file"
      end
      delete '/:id' do
        authorized?

        unless destroy_project(params[:id])
          error! "Cant delete project", 500
        end
        
        "ok"
      end

      desc "check versions of packages in project file"
      params do
        requires :id, :type => String, :desc => "Checks versions of packages in project"
      end
      get '/:id/check' do
        project = Project.find_by_id params[:id]
        
        if project.nil?
          error! "Project dont exist.", 500
        end

        Project.process_project(project)
        if project.dependencies.nil?
          error! "Project dont have external dependencies.", 500
        end
        deps = project.dependencies
        present deps, with: Entities::ProjectDependencyEntity   
      end

    end
  end
end
