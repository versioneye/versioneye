class SettingsController < ApplicationController

  before_filter :authenticate
  layout :resolve_layout

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

  def payments
    customer_id = current_user.stripe_customer_id
    @customer = nil
    if customer_id
      @customer = StripeService.fetch_customer customer_id
    end
  end

  # TODO test it
  def receipt
    @invoice = StripeService.get_invoice( params['invoice_id'] )
    # Ensure that the invoice belongs to the current logged in user!
    if @invoice && !@invoice.customer.eql?( current_user.stripe_customer_id )
      @invoice = nil
    end
    @billing_address = current_user.billing_address
  end

  def creditcard
    @page = "cc"
    plan = cookies.signed[:plan_selected]
    if plan
      @plan_name_id = plan
    end
    @billing_address = current_user.fetch_or_create_billing_address
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
    @user_notification = fetch_or_create_notification_setting current_user
  end

  def api
    @user_api = Api.find_or_initialize_by(user_id: current_user.id.to_s)
    @api_calls = 0
    if @user_api.api_key.nil?
      @user_api.api_key = "generate new value"
    else
      @api_calls = ApiCall.by_user(current_user).by_api_key(@user_api.api_key).count
    end
  end

  def update_api_key
    @user_api = Api.find_or_initialize_by(user_id: current_user.id.to_s)
    @user_api.generate_api_key!

    unless @user_api.save
      flash[:notice] << @user_api.errors.full_messages.to_sentence
    end
    redirect_to :back
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
    customer = nil
    if stripe_token && customer_id
      customer = StripeService.fetch_customer customer_id
    end
    if customer
      customer.update_subscription( :plan => @plan_name_id )
      user.plan = Plan.by_name_id @plan_name_id
      user.save
      flash[:success] = "We updated your plan successfully."
      redirect_to settings_plans_path
    else
      flash.now[:info] = "Please update your Credit Card information."
      @page = "cc"
      cookies.permanent.signed[:plan_selected] = @plan_name_id
      @billing_address = current_user.fetch_or_create_billing_address
      render settings_creditcard_path
    end
  end

  def updatecreditcard
    plan_name_id = params[:plan]
    stripe_token = params[:stripeToken]
    if stripe_token.nil? || stripe_token.empty?
      flash[:error] = "Sorry. But something went wrong. Please try again later."
      redirect_to settings_plans_path
      return
    end
    user = current_user
    customer = StripeService.create_or_update_customer user, stripe_token, plan_name_id
    user.stripe_token = stripe_token
    user.stripe_customer_id = customer.id
    user.save
    user.billing_address.update_from_params( params )
    flash[:success] = "Many Thanks. We just updated your plan."
    redirect_to settings_plans_path
  end

  def updateprofile
    fullname = params[:fullname]
    new_username = params[:new_username]
    location = params[:location]
    description = params[:description]
    blog = params[:blog]
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
    @user_notification = current_user.user_notification_setting
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
    Notification.disable_all_for_user(user.id)
    user.delete_user
    sign_out
    redirect_to "/"
  end

  private

    def resolve_layout
      case action_name
      when "receipt"
        "plain"
      else
        "application"
      end
    end

    def validates_privacy_value value
      return "everybody" if value.nil? || value.empty?
      return value if value.eql?("everybody") || value.eql?("nobody") || value.eql?("ru")
      return "everybody"
    end

end
