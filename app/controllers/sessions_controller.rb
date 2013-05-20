class SessionsController < ApplicationController

  force_ssl :only => [:new, :create] if Rails.env.production?

  def new
  end

  def create
    user = User.authenticate(params[:session][:email],
                             params[:session][:password])
    if user.nil?
      flash[:error] = "Invalid email/password combination."
      @title = "Sign in"
      redirect_to "/signin"
    elsif !user.activated?
      flash[:error] = "Your Account is not active. Please validate your E-Mail address by clicking the verification link in the verification E-Mail."
      redirect_to "/signin"
    else
      sign_in user
      if user.projects.empty?
        redirect_back_or( new_user_project_path )
      else
        redirect_back_or( user_projects_path )
      end
    end
  end

  def destroy
    sign_out
    redirect_to root_path
  end

end
