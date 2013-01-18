require 'grape'
require 'grape-swagger'

require 'products_api'
require 'services_api'
require 'projects_api'
require 'sessions_api'
require 'users_api'

module V1
  module Versioneye
    class API < Grape::API
      
      version 'v1', :using => :path
      
      format :json
      default_format :json

      #rescue_from :all

      mount VersionEye::ProductsApi
      mount VersionEye::ServicesApi
      mount VersionEye::ProjectsApi
      mount VersionEye::SessionsApi
      mount VersionEye::UsersApi

      add_swagger_documentation :base_path => "http://localhost:3000/api", 
                                :api_version => "v1",
                                :markdown => true, 
                                :hide_documentation_path => true

      before do
        header['Access-Control-Allow-Origin'] = '*'
        header['Access-Control-Request-Method'] = '*'
      end

    end
  end
end
