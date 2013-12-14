class Settings::ProfileController < ApplicationController

  before_filter :authenticate

  def index
    @user = current_user
    @user.new_username = @user.username
  end

  def update
    fullname     = params[:fullname]
    new_username = params[:new_username]
    location     = params[:location]
    description  = params[:description]
    blog         = params[:blog]
    password     = params[:password]
    if password.nil? || password.empty?
      flash[:error] = 'For security reasons. Please type in your current password.'
    elsif new_username.nil? || new_username.empty?
      flash[:error] = 'Please type in a username.'
    elsif !current_user.username.eql?(new_username) && !User.username_valid?(new_username)
      flash[:error] = "Username exist already. Please choose another username."
    elsif User.authenticate(current_user.email, password).nil?
      flash[:error] = "The password is wrong. Please try again."
    else
      @user = current_user
      @user.username = new_username
      @user.fullname = fullname
      @user.description = description
      @user.location = location
      @user.blog = blog
      @user.password = password
      if @user.save
        flash[:success] = "Profile updated."
      else
        flash[:error] = "Something went wrong. Please try again later."
      end
    end
    redirect_to settings_profile_path()
  end

end
