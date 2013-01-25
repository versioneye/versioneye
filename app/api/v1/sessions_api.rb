require 'grape'

require_relative 'helpers/session_helpers.rb'

module VersionEye
  class SessionsApi < Grape::API
    helpers SessionHelpers
    
    resource :sessions do
      desc "returns session info for authorized users", {
        notes: %q[If current user has active session, then this
                method will return 200 with short user profile.
                For othercase, it will return error message with status code 401.
              ]
      }
      get do
        authorized?
        
        user_api = Api.where(user_id: @current_user.id).shift
        {
          :fullname => @current_user.fullname,
          :api_key   => user_api.api_key
        }
      end

      desc "creates new sessions", {
        notes: %q[ You need to append your api_key to request. ]
      }
      params do
        requires :api_key, type: String,  :desc => "your personal token for API."
      end
      post do
        authorize(params[:api_key])
        (authorized?) ? "true" : "false"
      end

      desc "delete current session aka log out.", {
        notes: %q[Close current session. It's very handy method when you re-generated
                  your current API-key.]
      }
      delete do
        authorized?
        clear_session
        {:message => "Session is closed now."}
      end
    end
  end
end
