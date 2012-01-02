class UsersController < ApplicationController

  before_filter :authenticate, :except => [:show, :new, :create]
  before_filter :correct_user, :only   => [:edit, :update, :geigercounter]
  before_filter :admin_user,   :only   => :destroy

  def signup
    redirect_to :action => "new"
  end

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
    @user = User.find_by_username(params[:id])
    @title = "Edit your Profile"
  end

  def update
    @user = User.find_by_username(params[:id])
    if @user.update_attributes(params[:user])
      flash[:success] = "Profile updated."
      redirect_to @user
    else
      @title = "Edit user"
      render "edit"
    end
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
      @user = User.find_by_username(params[:id])
      redirect_to(root_path) unless current_user?(@user)
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end

end