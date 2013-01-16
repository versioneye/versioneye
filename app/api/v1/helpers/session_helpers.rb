module VersionEye
  module SessionHelpers
    def authorized? 
      @current_user = current_user()
      if @current_user.nil?
        error! "Not authorized request.", 401
      end
      @current_user  
    end

    def authorize(token)
      @current_user = User.authenticate_with_apikey(token)
      if @current_user.nil?
        error! "Not valid API token", 531
      end
      cookies[:api_key] = token 
      @current_user
    end

    def current_user 
      cookie_token = cookies[:api_key]
      @current_user ||= User.authenticate_with_apikey(cookie_token)
      @current_user
    end

    def clear_session
      cookies[:api_key] = nil
      @current_user = nil
    end

  end
end
