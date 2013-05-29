class Settings::DeleteController < ApplicationController

  before_filter :authenticate
  force_ssl if Rails.env.production?

  def index
  end

  def destroy
    password = params[:password]
    user = current_user
    if !user.password_valid?(password)
      flash[:error] = "The password is wrong. Please try again."
      redirect_to settings_delete_path()
      return
    end
    user.password = password
    Notification.remove_notifications( user )
    user.delete_user
    sign_out
    redirect_to "/"
  end

end
