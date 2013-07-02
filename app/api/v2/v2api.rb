require 'grape'
require 'grape-swagger'

require_relative 'v2_products_api'
require_relative 'v2_services_api'
require_relative 'v2_projects_api'
require_relative 'v2_sessions_api'
require_relative 'v2_users_api'

module V2
  class V2api < Grape::API

    version "v2", :using => :path
    default_format :json

    rescue_from :all #comment out if you want to see RAILS error pages & debug on cmd-line

    mount V2ProductsApi
    mount V2ServicesApi
    mount V2ProjectsApi
    mount V2SessionsApi
    mount V2UsersApi

   add_swagger_documentation :base_path => ENV['API_BASE_PATH'],
                             :class_name => "swagger_doc2",
                             :api_version => "v2" #,
                             #:markdown => true,
                             #:hide_format => true,
                             #:hide_documentation_path => true

    before do
      header "Access-Control-Allow-Origin", "*"
      header "Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, PATCH, DELETE"
      header "Access-Control-Request-Method", "*"
      header "Access-Control-Max-Age", "1728000"
      header "Access-Control-Allow-Headers", "api_key, Content-Type"

    end
 end
end
