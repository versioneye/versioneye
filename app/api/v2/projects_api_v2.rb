require 'grape'
require 'entities_v2'

require_relative 'helpers/project_helpers.rb'
require_relative 'helpers/session_helpers.rb'

module V2

  class ProjectsApiV2 < Grape::API
    helpers ProjectHelpers
    helpers SessionHelpers

    # rescue_from :all do |e|
    #   rack_response({ :message => "rescued from #{e.class.name} - message: #{e.message} - backtrace: #{e.backtrace}" })
    # end

    def self.fetch_project(user, proj_key)
      project = Project.by_user(user).where(project_key: proj_key).shift
      project = Project.by_user(user).where(_id: proj_key).shift if project.nil?
      project
    end

    resource :projects do

      before do
        track_apikey
      end

      desc "shows user`s projects", {
        notes: %q[

              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
      get do
        authorized?
        @user_projects = Project.by_user(@current_user)
        present @user_projects, with: EntitiesV2::ProjectEntity
      end


      desc "shows the project's information", {
        notes: %q[ It shows detailed info of your project. ]
      }
      params do
        requires :project_key, :type => String, :desc => "Project ID"
      end
      get '/:project_key' do
        authorized?
        project_key = params[:project_key]
        project     = fetch_project_by_key_and_user(project_key, current_user)
        if project.nil?
          error! "Project `#{params[:project_key]}` don't exists", 400
        end
        project = add_dependency_licences(project)
        present project, with: EntitiesV2::ProjectEntity, type: :full
      end


      desc "upload project file", {
        notes: %q[

              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
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

        datafile = ActionDispatch::Http::UploadedFile.new( params[:upload] )
        project_file = {'datafile' => datafile}

        @project = upload_and_store( project_file )
        if @project.nil?
          error! "Can't save uploaded file. Probably our fileserver got cold.", 500
        end

        @project = add_dependency_licences(@project)
        present @project, with: EntitiesV2::ProjectEntity, :type => :full
      end


      desc "update project with new file", {
        notes: %q[

              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
      params do
        requires :project_key, :type => String, :desc => "Project specific identificator"
        requires :project_file, type: Hash, desc: "Project file - [maven.pom, Gemfile ...]"
      end
      post '/:project_key' do
        authorized?

        @project = fetch_project_by_key_and_user( params[:project_key], current_user )
        if @project.nil?
          error! "Project `#{params[:project_key]}` don't exists", 400
        end

        if params[:project_file].nil?
          error! "Didnt submit file or used wrong parameter.", 400
        end

        if params[:project_file].is_a? String
          error! "File field is plain text. It should be multipart submition.", 400
        end

        datafile = ActionDispatch::Http::UploadedFile.new( params[:project_file] )
        project_file = {'datafile' => datafile}

        new_project = upload project_file
        if new_project.nil?
          error! "Can't save uploaded file. Probably our fileserver got cold.", 500
        end

        @project.update_from new_project
        project = add_dependency_licences(project)

        present @project, with: EntitiesV2::ProjectEntity, :type => :full
      end


      desc "delete given project", {
        notes: %q[

              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
      params do
        requires :project_key, :type => String, :desc => "Delete project file"
      end
      delete '/:project_key' do
        authorized?
        proj_key = params[:project_key]
        error!("Project key can't be empty", 400) if proj_key.nil? or proj_key.empty?

        project = Project.by_user(@current_user).where(project_key: proj_key).shift
        if project.nil? or not destroy_project(project.id)
          project = Project.by_user(@current_user).where(_id: proj_key).shift
          if project.nil?
            error! "Deletion failed because you don't have such project: #{proj_key}", 500
          end
        end

        {success: true, message: "Project deleted successfully."}
      end


      desc "get grouped view of licences for dependencies", {
        notes: %q[

              To use this resource you need either an active session or you have to append
              your API Key to the URL as parameter. For example: "?api_key=666_your_api_key_666"

            ]
      }
      params do
        requires :project_key, :type => String, :desc => "Project specific identifier"
      end
      get '/:project_key/licenses' do
        authorized?

        @project = ProjectsApiV2.fetch_project @current_user, params[:project_key]
        error!("Project `#{params[:project_key]}` don't exists", 400) if @project.nil?

        licenses = {}

        @project.dependencies.each do |dep|
          license = "unknown"
          unless dep[:prod_key].nil?
            product = Product.fetch_product( dep.language, dep.prod_key )
            license = product.license_info
          end

          licenses[license] ||= []

          prod_info = {
            :name => dep.name,
            :prod_key => dep[:prod_key],
          }
          licenses[license] << prod_info
        end

        {success: true, licenses: licenses}
      end

    end

  end
end
