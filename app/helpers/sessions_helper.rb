module SessionsHelper

  def sign_in(user)
    reset_session
    cookies.permanent.signed[:remember_token] = [user.id, user.salt]
    self.current_user = user
  end

  def sign_out
    cookies.delete(:remember_token)
    self.current_user = nil
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user
    @current_user ||= user_from_remember_token
  end

  def current_user?(user)
    return false if user.nil? 
    return nil if current_user.nil? 
    user.username.eql? current_user.username
  end

  def signed_in?
    !current_user.nil?
  end
  
  def signed_in_admin?
    signed_in? && current_user.admin?
  end

  def authenticate
    return true if signed_in?
    deny_access
    return false 
  end

  def deny_access
    store_location
    redirect_to signin_path, :notice => "Please sign in to access this page."
  end

  def redirect_back_or(default)
    redirect_to(session[:return_to] || default, :status => 302)
    clear_return_to
  end

  def set_locale
    locale = "en"
    if (locale && !locale.empty?)
      I18n.locale = locale
    elsif I18n.locale.nil? 
      I18n.locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    end
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    nil
  end

  private

    def force_http
      if request.ssl? && Rails.env.production?
        redirect_to :protocol => 'http://', :status => :moved_permanently
      end
    end

    def user_from_remember_token
      User.authenticate_with_salt(*remember_token)
    end

    def remember_token
      cookies.signed[:remember_token] || [nil, nil]
    end

    def store_location
      session[:return_to] = request.fullpath
    end

    def clear_return_to
      session[:return_to] = nil
    end

end