class SettingsController < ApplicationController

  before_filter :authenticate

  force_ssl

  def name
    @user = current_user
    @user.new_username = @user.username
  end

  def password
    @user = current_user
    @user.new_username = @user.username
  end

  def privacy
    @user = current_user
    @user.new_username = @user.username
  end

  def profile
    @user = current_user
  end

  def links
    @userlinkcollection = Userlinkcollection.find_all_by_user( current_user.id )
    if @userlinkcollection.nil?
      @userlinkcollection = Userlinkcollection.new
    end
  end

  def updatenames
    fullname = params[:fullname]
    new_username = params[:new_username] 
    password = params[:password]
    
    if password.nil? || password.empty? 
      flash[:error] = "For security reasons. Please type in your current password."
    elsif new_username.nil? || new_username.empty?
      flash[:error] = "Please type in a username."
    elsif !current_user.username.eql?(new_username) && !User.username_valid?(new_username)
      flash[:error] = "Username exist already. Please choose another username."
    elsif User.authenticate(current_user.email, password).nil? 
      flash[:error] = "The password is wrong. Please try again."
    else
      @user = current_user   
      @user.username = new_username
      @user.fullname = fullname
      @user.password = password
      if @user.save
        flash[:success] = "Profile updated."
      else
        flash[:error] = "Something went wrong. Please try again later."
      end
    end         
    redirect_to settings_name_path()
  end
  
  def updatepassword    
    password = params[:password]
    new_password = params[:new_password]
    repeat_new_password = params[:repeat_new_password]
    
    if password.nil? || password.empty? || new_password.nil? || new_password.empty? || repeat_new_password.nil? || repeat_new_password.empty? 
      flash[:error] = "Please fill out all input fields."
    elsif !new_password.eql?(repeat_new_password)
      flash[:error] = "The new password does not match with the repeat new password. Please try again."
    elsif User.authenticate(current_user.email, password).nil? 
      flash[:error] = "The password is wrong. Please try again."
    else
      @user = current_user         
      if @user.update_password(current_user.email, password, new_password)
        flash[:success] = "Profile updated."
      else
        flash[:error] = "Something went wrong. Please try again later."
      end
    end         
    redirect_to settings_password_path()
  end
  
  def updateprivacy
    privacy_products = validates_privacy_value params[:following_products]
    privacy_comments = validates_privacy_value params[:comments]
    password = params[:password]
    user = current_user
    user.privacy_products = privacy_products
    user.privacy_comments = privacy_comments
    user.password = password
    if user.save
      flash[:success] = "Profile updated."
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to settings_privacy_path()
  end

  def updateprofile
    location = params[:location]
    description = params[:description]
    blog = params[:blog]
    password = params[:password]
    p "#{location} - #{description} - #{blog}"

    user = current_user
    user.description = description
    user.location = location
    user.blog = blog
    user.password = password
    if user.save
      flash[:success] = "Profile updated."
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to settings_profile_path()
  end

  def updatelinks
    @userlinkcollection = Userlinkcollection.find_all_by_user( current_user.id )
    if @userlinkcollection.nil?
      @userlinkcollection = Userlinkcollection.new
    end
    @userlinkcollection.github = params[:github]
    @userlinkcollection.stackoverflow = params[:stackoverflow]
    @userlinkcollection.linkedin = params[:linkedin]
    @userlinkcollection.xing = params[:xing]
    @userlinkcollection.twitter = params[:twitter]
    @userlinkcollection.facebook = params[:facebook]
    @userlinkcollection.gulp = params[:gulp]
    @userlinkcollection.user_id = current_user.id
    if @userlinkcollection.save
      flash[:success] = "Profile updated."
    else
      flash[:error] = "Something went wrong. Please try again later."
    end
    redirect_to settings_links_path()
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
    Follower.unfollow_all_by_user(user.id)
    Notification.disable_all_for_user(user.id)
    Blogcomment.anonym_user(user.id)
    user.delete_user
    sign_out
    redirect_to "/"
  end

  private 

  	def validates_privacy_value value
      return "everybody" if value.nil? || value.empty?
      return value if value.eql?("everybody") || value.eql?("nobody") || value.eql?("ru")
      return "everybody"
    end

end