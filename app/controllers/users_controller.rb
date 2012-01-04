class UsersController < ApplicationController

  before_filter :authenticate, :except => [:show, :new, :create]
  before_filter :correct_user, :only   => [:edit, :update]
  before_filter :admin_user,   :only   => :destroy

  def new
    @user = User.new
    @title = "sign up"
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      sign_in @user
      flash[:success] = "Welcome to VersionEye"
      redirect_to @user
    else 
      @title = "Sign up"
      render 'new'
    end
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

end