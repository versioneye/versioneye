require 'grape'
require 'grape-swagger'

require 'products_api_v1'
require 'services_api_v1'
require 'projects_api_v1'
require 'sessions_api_v1'
require 'users_api_v1'

module V1
  class ApiV1 < Grape::API
    version 'v1', :using => :path
    format :json
    default_format :json

    #rescue_from :all #comment out if you want to see RAILS error pages & debug on cmd-line

    mount ProductsApiV1
    mount ServicesApiV1
    mount ProjectsApiV1
    mount SessionsApiV1
    mount UsersApiV1

    add_swagger_documentation :base_path => ENV['API_BASE_PATH'],
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

