class Settings::PasswordController < ApplicationController

  before_filter :authenticate

  def index
    @user = current_user
    @user.new_username = @user.username
  end

  def update
    password = params[:password]
    new_password = params[:new_password]
    repeat_new_password = params[:repeat_new_password]

    if password.nil? || password.empty? || new_password.nil? || new_password.empty? || repeat_new_password.nil? || repeat_new_password.empty?
      flash[:error] = 'Please fill out all input fields.'
    elsif !new_password.eql?(repeat_new_password)
      flash[:error] = 'The new password does not match with the repeat new password. Please try again.'
    elsif User.authenticate(current_user.email, password).nil?
      flash[:error] = 'The password is wrong. Please try again.'
    else
      @user = current_user
      if @user.update_password(current_user.email, password, new_password)
        flash[:success] = 'Profile updated.'
      else
        flash[:error] = 'Something went wrong. Please try again later.'
      end
    end
    redirect_to settings_password_path()
  end

end
