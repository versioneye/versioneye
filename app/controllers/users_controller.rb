class UsersController < ApplicationController

  before_filter :authenticate, :only => [:edit, :update, :destroy]
  before_filter :correct_user, :only => [:edit, :update]
  before_filter :admin_user,   :only => [:destroy]
  before_filter :set_locale

  force_ssl :only => [:new, :create, :activate]
  #before_filter :force_http , :only => [:show, :favoritepackages, :comments]

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
    if !User.email_valid?(@user.email)
      flash.now[:error] = "The E-Mail address is already taken. Please choose another E-Mail."
      render 'new'
    elsif @user.terms != true
      flash.now[:error] = "You have to accept the Conditions of Use AND the Data Aquisition."
      render 'new'
    elsif @user.password.nil? || @user.password.empty? || @user.password.size < 5
      flash.now[:error] = "Please choose a password with at least 5 characters."
      render 'new'
    else 
      @user = User.new(params[:user])
      @user.datenerhebung = true
      @user.create_username
      @user.create_verification
      if @user.save
        @user.send_verification_email
        User.new_user_email(@user)
      else 
        render 'new'
      end
    end    
  end
  
  def show
    @user = User.find_by_username(params[:id])
    @page = "profile"
    
    if ( !@user.nil? )
      product_ids = Follower.find_product_ids_for_user( @user.id )
      @languages = Product.get_unique_languages_for_product_ids(product_ids)
      @userlinkcollection = Userlinkcollection.find_all_by_user( @user.id )

      @products = Array.new
      if has_permission_to_see_products( @user, current_user ) && !@user.nil?
        @products = @user.fetch_my_products.paginate(:page => params[:page], :per_page => 3)
        @prod_count = @user.fetch_my_products_count
        @prod_count = 0 if @prod_count.nil?
      end
      
      @comments = Array.new
      if has_permission_to_see_comments( @user, current_user ) && !@user.nil?
        @comments = Versioncomment.find_by_user_id( @user.id ).paginate(:page => params[:page], :per_page => 3)
        @comments_count = Versioncomment.count_by_user_id( @user.id )
        @comments_count = 0 if @comments_count.nil?
      end

      if signed_in?
        @my_product_ids = current_user.fetch_my_product_ids
      end
    else 
      flash.now[:error] = "There is no user with the given username"
    end
    
    respond_to do |format|
      format.html {  }
      format.json { render :json => @user.to_json(:only => [:fullname, :username ] ) }
    end        
  end
  
  def favoritepackages
    @page = "profile"
    @user = User.find_by_username(params[:id])
    product_ids = Follower.find_product_ids_for_user( @user.id )
    @languages = Product.get_unique_languages_for_product_ids(product_ids)
    @userlinkcollection = Userlinkcollection.find_all_by_user( @user.id )
    @products = Array.new
    if has_permission_to_see_products( @user, current_user ) && !@user.nil?
      @products = @user.fetch_my_products.paginate(:page => params[:page]) 
      @count = @user.fetch_my_products_count
    end    
    @my_product_ids = Array.new
    if signed_in?
      @my_product_ids = current_user.fetch_my_product_ids
    end
    respond_to do |format|
      format.html {  }
      format.json { render :json => @products.to_json(:only => [:name, :version, :prod_key, :group_id, :artifact_id, :language] ) }
    end
  end
  
  def comments
    @page = "profile"
    @user = User.find_by_username(params[:id])
    product_ids = Follower.find_product_ids_for_user( @user.id )
    @languages = Product.get_unique_languages_for_product_ids(product_ids)
    @userlinkcollection = Userlinkcollection.find_all_by_user( @user.id )
    @comments = Array.new
    if has_permission_to_see_comments( @user, current_user ) && !@user.nil?
      @comments = Versioncomment.find_by_user_id( @user.id ).paginate(:page => params[:page])
      @count = Versioncomment.count_by_user_id( @user.id )
    end
    respond_to do |format|
      format.html {  }
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
  
  def activate
    verification = params[:verification]
    if User.activate!(verification)
      flash.now[:success] = "Congratulation. Your Account is activated. Please Sign In."
      return 
    end
    if UserEmail.activate!(verification)
      flash.now[:success] = "Congratulation. Your E-Mail Address is now verified."
      return 
    end
    flash.now[:error] = "The activation code could not be found. Maybe your Account is already activated."
  end

  def users_location
    user = User.find_by_username(params[:id])
    location = "Berlin"
    if user 
      location = user.location
    end
    respond_to do |format|
      format.json { 
        render :json => "{\"location\": \"#{location}\"}"
      }
    end
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
    User.find_by_username(params[:id]).delete_user
    flash[:success] = "User deleted"
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