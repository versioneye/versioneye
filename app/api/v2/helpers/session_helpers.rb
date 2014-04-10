
module SessionHelpers

  def authorized?
    @api_key = header['api_key']
    @api_key = params[:api_key]
    cookies[:api_key] = @api_key unless @api_key.nil?
    @current_user = current_user()
    if @current_user.nil?
      error! "Not authorized request.", 401
    end
    @current_user
  end

  def authorize( token )
    @current_user = User.authenticate_with_apikey(token)
    if @current_user.nil?
      error! "Not valid API token", 531
    end
    cookies[:api_key] = token
    @current_user
  end

  def current_user
    cookie_token  = cookies[:api_key]
    @current_user = authorize(cookie_token) unless cookie_token.nil?
    @current_user
  end

  def github_connected?( user )
    return true if user.github_account_connected?
    error! "Github account is not connected. Check your settings on versioneye.com", 401
    false
  end

  def clear_session
    cookies[:api_key] = nil
    cookies.delete :api_key
    @current_user = nil
  end

  def track_apikey
    api_key = (request[:api_key] or request.cookies["api_key"])

    user_api = Api.where(api_key: api_key).shift
    return false if api_key.nil? or user_api.nil?

    user = User.find_by_id user_api.user_id

    call_data = {
      fullpath: "#{request.host_with_port}/#{request.fullpath}",
      ip:       request.ip,
      api_key:  api_key,
      user_id:  (user.nil?) ? nil : user.id
    }
    new_api_call =  ApiCall.new call_data
    new_api_call.save
  end

end
