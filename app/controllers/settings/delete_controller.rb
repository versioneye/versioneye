class Settings::DeleteController < ApplicationController

  before_filter :authenticate

  def index
  end

  def destroy
    password = params[:password]
    user = current_user
    unless user.password_valid?(password)
      flash[:error] = 'The password is wrong. Please try again.'
      redirect_to settings_delete_path()
      return
    end
    user.password = password
    UserService.delete user
    sign_out
    redirect_to "/"
  end

end
