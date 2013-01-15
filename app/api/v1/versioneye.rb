require 'grape'
require 'products_api'
require 'services_api'
require 'projects_api'
require 'sessions_api'

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
    end
  end
end
