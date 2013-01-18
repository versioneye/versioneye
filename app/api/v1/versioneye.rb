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
    
      rescue_from :all

      mount VersionEye::ProductsApi
      mount VersionEye::ServicesApi
      mount VersionEye::ProjectsApi
      mount VersionEye::SessionsApi
      mount VersionEye::UsersApi
      
      add_swagger_documentation :api_version => "v1"

    end
  end
end
