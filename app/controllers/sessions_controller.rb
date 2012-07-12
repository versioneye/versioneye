class SessionsController < ApplicationController

  force_ssl :only => [:new, :create]

  def new
    @page = "SignIn"
  end
  
  def create
    user = User.authenticate(params[:session][:email],
                             params[:session][:password])                             
    respond_to do |format|
      format.html {
        if user.nil?
          flash[:error] = "Invalid email/password combination."
          @title = "Sign in"
          redirect_to "/signin"
        elsif !user.activated?
          flash[:error] = "Your Account is not active. Please validate your E-Mail address by clicking the verification link in the verification E-Mail."
          redirect_to "/signin"
        else
          sign_in user
          redirect_back_or( "/news" )
        end
      }
      format.json { 
        if user.nil?
          render :json => {'user' => 'null'}.to_json 
        else
          sign_in user
          render :json => user.as_json("") 
        end        
      }
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