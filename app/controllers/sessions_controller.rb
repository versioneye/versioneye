class SessionsController < ApplicationController

  before_action :enterprise_activated?


  def new
    if signed_in?
      orga  = get_orga_for_login( current_user )
      redirect_to projects_organisation_path( orga ) and return
    end
  end


  def create
    redirect_url = params[:redirect_url]

    user = AuthService.auth(params[:session][:email],
                            params[:session][:password])
    if user.nil?
      flash[:error] = 'Invalid email/password combination.'
      @title = 'Sign in'
      redirect_back
    elsif !user.admin 
      flash[:error] = 'The login process is disabled for right now.'
      redirect_back
    elsif !user.activated?
      flash[:error] = 'Your Account is not active. Please validate your email address by clicking the verification link in the verification E-Mail.'
      redirect_back
    else
      sign_in user
      if current_user.admin?
        redirect_to settings_activation_path
      else
        if redirect_url
          redirect_to redirect_url
        else
          rpath = get_redirect_path( user )
          redirect_back_or( rpath )
        end
      end
    end
  end


  def destroy
    sign_out
    redirect_to root_path
  end


  private


    def get_redirect_path user
      if Settings.instance.orga_creation_admin_only == true && user.admin == false
        return notifications_path
      else
        orga  = get_orga_for_login( user )
        if orga
          rpath = projects_organisation_path( orga )
        else
          rpath = settings_profile_path( user )
        end
        return rpath
      end
    end


end
