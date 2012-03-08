class UsersController < ApplicationController

  before_filter :authenticate, :except => [:show, :showfavoriteproducts, :showcomments, :new, :create, :activate, :iforgotmypassword, :resetpassword]
  before_filter :correct_user, :only   => [:edit, :update, :activate]
  before_filter :admin_user,   :only   => :destroy
  before_filter :set_locale

  def home
    if signed_in?
      redirect_to user_path current_user
    else  
      redirect_to root_path
    end
  end
  
  def new
    @user = User.new    
  end
  
  def create
    @user = User.new(params[:user])
    if !User.username_valid?(@user.username)
      flash.now[:error] = "The username is already taken. Please choose another username."
      render 'new'
    elsif !User.email_valid?(@user.email)
      flash.now[:error] = "The E-Mail address is already taken. Please choose another E-Mail."
      render 'new'
    elsif @user.terms != true || @user.datenerhebung != true
      flash.now[:error] = "You have to accept the Conditions of Use AND the Data Aquisition."
      render 'new'
    else 
      @user = User.new(params[:user])
      @user.create_verification
      if @user.save
        @user.send_verification_email
      else 
        render 'new'
      end
    end    
  end
  
  def show
    @user = User.find_by_username(params[:id])
    respond_to do |format|
      format.html { @user }
      format.json { render :json => @user }
    end        
  end
  
  def showfavoriteproducts
    @user = User.find_by_username(params[:id])
    @products = Array.new
    if has_permission_to_see_products( @user, current_user )
      @products = @user.fetch_my_products unless @user.nil?    
    end    
    respond_to do |format|
      format.html { render 'show' }
      format.json { render :json => @products }
    end
  end
  
  def showcomments
    @user = User.find_by_username(params[:id])
    @comments = Array.new
    if has_permission_to_see_comments( @user, current_user )
      @comments = Versioncomment.find_by_user_id( @user.id ) unless @user.nil?
    end
    respond_to do |format|
      format.html { render 'show' }
      format.json { render :json => @comments }
    end        
  end
  
  def notifications
    result = 0
    user = User.find_by_username(params[:id])
    if signed_in? && user.id == current_user.id
      notificaaions = Follower.find_notifications_by_user_id(current_user.id)
      result = notificaaions.count unless notificaaions.nil?
    end
    respond_to do |format|
      format.json { render :json => result }
    end
  end
  
  def edit
    @user = User.find_by_username(params[:id])
    @user.new_username = @user.username
  end  
  
  def activate
    verification = params[:verification]
    if User.activate!(verification)
      flash[:success] = "Congratulation. Your Account is activated. Please Sign In."
    else
      flash[:error] = "The activation code could not be found. Maybe your Account is already activated."
    end
    redirect_to '/signin'
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
    redirect_to edit_user_path( @user )
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
    redirect_to edit_user_path( @user )
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
    redirect_to edit_user_path( @user )
  end
  
  def iforgotmypassword
  end
  
  def resetpassword
    email = params[:email]
    user = User.find_by_email(email)
    if user.nil? 
      flash[:error] = "A user with the given E-Mail address could not be found."      
    else
      user.reset_password
      flash[:success] = "Please check your E-Mails. You should receive an E-Mail with a new password."
    end    
    redirect_to iforgotmypassword_path
  end

  def destroy
    User.find_by_username(params[:id]).destroy
    flash[:success] = "User destroyed"
    redirect_to users_path
  end

  private

    def correct_user
      @user = User.find_by_username(params[:id])
      redirect_to(root_path) unless current_user?(@user)
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end
    
    def set_locale
      locale = params[:locale]
      if (!locale.nil? && !locale.empty?)
        I18n.locale = locale
      else  
        I18n.locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
      end
    rescue
      nil
    end
    
    def validates_privacy_value value
      return "everybody" if value.nil? || value.empty?
      return value if value.eql?("everybody") || value.eql?("nobody") || value.eql?("ru")
      return "everybody"
    end
    
    

end