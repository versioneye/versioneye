class SessionsController < ApplicationController

  before_filter :enterprise_activated?

  def new
  end

  def create
    redirect_url = params[:redirect_url]

    user = User.authenticate(params[:session][:email],
                             params[:session][:password])
    if user.nil?
      flash[:error] = 'Invalid email/password combination.'
      @title = 'Sign in'
      redirect_to :back
    elsif !user.activated?
      flash[:error] = 'Your Account is not active. Please validate your email address by clicking the verification link in the verification E-Mail.'
      redirect_to :back
    else
      sign_in user
      if current_user.admin?
        redirect_to settings_emailsettings_path
      else
        if redirect_url
          redirect_to redirect_url
        elsif user.projects.empty?
          redirect_back_or( user_packages_i_follow_path )
        else
          redirect_back_or( user_projects_path )
        end
      end
    end
  end

  def destroy
    sign_out
    redirect_to root_path
  end

end
