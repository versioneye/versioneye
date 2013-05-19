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
      redirect_back_or( "/user/projects" )
    end
  end

  def destroy
    sign_out
    redirect_to root_path
  end

  def android_registrationid
    registration_id = params[:registration_id]
    user = current_user
    if !user.nil?
      user.registrationid = registration_id
      user.save
    end
  end

end
