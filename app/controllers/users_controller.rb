class UsersController < ApplicationController

  before_filter :authenticate, :except => [:show, :new, :create, :activate, :iforgotmypassword, :resetpassword]
  before_filter :correct_user, :only   => [:edit, :update, :activate]
  before_filter :admin_user,   :only   => :destroy
  before_filter :set_locale

  def new
    @user = User.new    
  end
  
  def home
    if signed_in?
      redirect_to user_path current_user
    else  
      redirect_to root_path
    end
  end

  def create
    @user = User.new(params[:user])
    if !User.username_valid?(@user.username)
      flash.now[:error] = "The username is already taken. Please choose another username."
      render 'new'
    elsif !User.email_vaild?(@user.email)
      flash.now[:error] = "The E-Mail address is already taken. Please choose another E-Mail."
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
  
  def activate
    verification = params[:verification]
    if User.activate!(verification)
      flash[:success] = "Congratulation. Your Account is activated. Please Sign In."
    else
      flash[:error] = "The activation code could not be found. Maybe your Account is already activated."
    end
    redirect_to '/signin'
  end

  def edit
    @user = User.find(:first, :conditions => ['username = ?', params[:id] ] )
    @user.new_username = @user.username
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

  def show
    @user = User.find(:first, :conditions => ['username = ?', params[:id] ] )
    @products = Array.new
    @products = @user.fetch_my_products unless @user.nil?    
    respond_to do |format|
      format.html { @products }
      format.json { render :json => @products }
    end        
  end

  def destroy
    User.find_by_username(params[:id]).destroy
    flash[:success] = "User destroyed"
    redirect_to users_path
  end

  private

    def correct_user
      @user = User.find(:first, :conditions => ['username = ?', params[:id] ] )
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

end