require 'grape'
require 'products_api'
require 'services_api'
require 'projects_api'

module V1
  module Versioneye
    class API < Grape::API
      version 'v1', :using => :path
      format :json
    
      rescue_from :all
     
      helpers do
        def api_response(success = false, message = nil, data = nil)
          {
            :success  => success,
            :message  => message,
            :data     => data
          }
        end
      end

      mount VersionEye::ProductsApi
      mount VersionEye::ServicesApi
      mount VersionEye::ProjectsApi
    end
  end
end
