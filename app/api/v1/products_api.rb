require 'grape'

module VersionEye
  class  ProductsApi < Grape::API
    
    resource :products do
      desc "ping"
      get :ping do
        api_response(true, "ping", "pong")
      end
    end
  end
end
