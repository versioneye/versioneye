require 'grape'
require 'grape-swagger'

require_relative 'products_api_v2'
require_relative 'services_api_v2'
require_relative 'projects_api_v2'
require_relative 'sessions_api_v2'
require_relative 'users_api_v2'
require_relative 'github_api_v2'

module V2
  class ApiV2 < Grape::API

    version "v2", :using => :path
    format :json
    default_format :json

    #rescue_from :all #comment out if you want to see RAILS error pages & debug on cmd-line

    mount ProductsApiV2
    mount ServicesApiV2
    mount ProjectsApiV2
    mount SessionsApiV2
    mount UsersApiV2
    mount GithubApiV2

    add_swagger_documentation :base_path => ENV['API_BASE_PATH'],
                              :class_name => "swagger_doc2",
                              :markdown => true,
                              :hide_format => true,
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
