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
      #format :json
      default_format :json

      rescue_from :all

      mount VersionEye::ProductsApi
      mount VersionEye::ServicesApi
      mount VersionEye::ProjectsApi
      mount VersionEye::SessionsApi
      mount VersionEye::UsersApi

      add_swagger_documentation :base_path => "http://127.0.0.1:3000/api", 
                                :api_version => "v1",
                                :markdown => true, 
                                :hide_documentation_path => true
      before do
        header "Access-Control-Allow-Origin", "*"
        header "Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, PATCH, DELETE"
        header "Access-Control-Request-Method", "*"
        header "Access-Control-Max-Age", "1728000"
        header "Access-Control-Allow-Headers", "api_key, Content-Type"
      end
   end
  end
end
