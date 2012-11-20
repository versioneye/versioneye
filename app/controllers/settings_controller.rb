class SettingsController < ApplicationController

  before_filter :authenticate

  force_ssl

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
    @user.new_username = @user.username
  end

  def plans
    @plan = current_user.plan  
  end

  def creditcard
    @page = "cc"
    plan = cookies.signed[:plan_selected]
    if plan 
      @plan_name_id = plan
    end
  end

  def links
    @userlinkcollection = Userlinkcollection.find_all_by_user( current_user.id )
    if @userlinkcollection.nil?
      @userlinkcollection = Userlinkcollection.new
    end
  end

  def connect
    @user = current_user
  end

  def emails
    @user = current_user
  end

  def notifications
    @user_notification = current_user.notification_settings
    if @user_notification.nil?
      @user_notification = UserNotificationSetting.new 
      @user_notification.user_id = current_user.id.to_s
      @user_notification.save
    end
  end

  def disconnect
    user = current_user
    service = params[:service]
    if service && service.eql?("twitter")
      user.twitter_id = nil
      user.twitter_token = nil
      user.twitter_secret = nil
    elsif service && service.eql?("facebook")
      user.fb_id = nil
      user.fb_token = nil
    elsif service && service.eql?("github")
      user.github_id = nil
      user.github_token = nil 
      user.github_scope = nil
    end
    user.save
    redirect_to settings_connect_path
  end

  def updateplan 
    @plan_name_id = params[:plan]
    user = current_user
    stripe_token = user.stripe_token
    customer_id = user.stripe_customer_id
    if stripe_token && customer_id
      customer = Stripe::Customer.retrieve( customer_id )
      customer.update_subscription( :plan => @plan_name_id )
      user.plan_name_id = @plan_name_id
      user.save
      flash[:success] = "We updated your plan successfully."
      redirect_to settings_plans_path
    else 
      flash.now[:info] = "Please update your Credit Card information."
      @page = "cc"
      cookies.permanent.signed[:plan_selected] = @plan_name_id
      render settings_creditcard_path
    end
  end

  def updatecreditcard
    plan_name_id = params[:plan]
    stripe_token = params[:stripeToken]

    if stripe_token.nil? || stripe_token.empty?
      flash.now[:success] = "Sorry. But something went wrong. Please try again later."
      redirect_to settings_plans_path
      return 
    end
    
    user = current_user
    customer = nil
    if user.stripe_customer_id 
      customer = Stripe::Customer.retrieve( user.stripe_customer_id )
      customer.card = stripe_token
      customer.save
      customer.update_subscription( :plan => plan_name_id )
    else 
      customer = Stripe::Customer.create(
        :card => stripe_token,
        :plan => plan_name_id,
        :email => user.email
      )  
    end
    user.stripe_token = stripe_token
    user.stripe_customer_id = customer.id
    user.plan_name_id = plan_name_id
    user.save
    flash.now[:success] = "Many Thanks. We just updated your plan."
    redirect_to settings_plans_path
  end

  def updateprofile
    fullname = params[:fullname]
    new_username = params[:new_username] 
    location = params[:location]
    description = params[:description]
    blog = params[:blog]
    password = params[:password]
    p "#{location} - #{description} - #{blog}"
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

  def add_email
    email = params[:email]

    user = User.find_by_email(email)
    user_email = UserEmail.find_by_email(email)
    if user || user_email
      flash[:error] = "The E-Mail Address exist already in our system. Please choose another one."
      redirect_to settings_emails_path()
      return 
    end

    user_email = UserEmail.new
    user_email.email = email 
    user_email.user_id = current_user.id
    user_email.create_verification
    if user_email.save 
      UserMailer.verification_email_only(current_user, user_email.verification, user_email.email).deliver
      flash[:success] = "E-Mail Address added."
    else 
      flash[:error] = "E-Mail Address is not valid."
    end 
    redirect_to settings_emails_path()
  end

  def delete_email
    email = params[:email]
    user_email = current_user.get_email(email)
    if user_email 
      user_email.remove
    end
    redirect_to settings_emails_path()
  end

  def updatenotifications
    news = params[:general_news]
    features = params[:new_feature_news]
    @user_notification = current_user.notification_settings
    @user_notification.newsletter_news = news 
    @user_notification.newsletter_features = features
    if @user_notification.save 
      flash[:success] = "Your changes have been saved successfully."
    else 
      flash[:error] = "An error occured. Please try again later."
    end
    redirect_to settings_notifications_path
  end

  def make_email_default
    email = params[:email]
    user = current_user
    user_email = user.get_email(email)
    if user_email && user_email.verified? 
      orig_email = user.email 
      user.email = user_email.email 
      user.save 
      user_email.email = orig_email
      user_email.save
      flash[:success] = "Default E-Mail Address changed successfully."
    else 
      flash[:error] = "An error occured. Please try again later."
    end
    redirect_to settings_emails_path()
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