class SessionsController < ApplicationController

  def new
    @title = "Sign in"
  end
  
  def create
    user = User.authenticate(params[:session][:email],
                             params[:session][:password])
    if user.nil?
      flash.now[:error] = "Invalid email/password combination."
      @title = "Sign in"
      render "new"
    else
      sign_in user
      redirect_back_or( user_path(user) ) 
    end
  end
  
  def test_login()
    user = User.authenticate(params[:email],
                             params[:password]);
    respond_to do |format|
      format.json { render :json => user.as_json }
    end
  end
  
  def destroy
    sign_out
    redirect_to root_path
  end

end