require 'grape'

require_relative 'helpers/session_helpers.rb'

module VersionEye
  class SessionsApi < Grape::API
    helpers SessionHelpers

    resource :sessions do
      desc "returns session info for authorized users'"
      get do
        authenticated?
        
        user_api = Api.where(user_id: @current_user.id).shift
        {
          :fullname => @current_user.fullname,
          :api_key   => user_api.api_key
        }
      end

      desc "creates new sessions"
      params do
        requires :api_key, :type => String, :desc => "your personal token for API."
      end
      post do
        authorize(params[:api_key])
      end

      desc "delete current session aka log out."
      delete do
        clear_session
        {:message => "Session is closed now."}
      end
    end
  end
end
