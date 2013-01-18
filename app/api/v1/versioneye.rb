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

      add_swagger_documentation api_version: 1.0,
                                markdown: true,
                                base_path: "http://127.0.0.1:3000/v1"

      before do
        header['Access-Control-Allow-Origin'] = '*'
        header['Access-Control-Request-Method'] = '*'
      end

    end
  end
end
