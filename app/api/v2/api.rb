require 'grape'
require 'grape-swagger'

require_relative 'products_api'
require_relative 'services_api'
require_relative 'projects_api'
require_relative 'sessions_api'
require_relative 'users_api'

module V2
  class API < Grape::API
    version 'v2', :using => :path
    format :json
    default_format :json

    rescue_from :all #comment out if you want to see RAILS error pages & debug on cmd-line

    mount ProductsApi
    mount ServicesApi
    mount ProjectsApi
    mount SessionsApi
    mount UsersApi

    add_swagger_documentation :base_path => ENV['API_BASE_PATH'] + '2', 
                              :api_version => "v2",
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
