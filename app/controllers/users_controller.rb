class UsersController < ApplicationController

  before_filter :authenticate, :only => [:update, :index, :update_permissions]
  before_filter :correct_user, :only => [:update]
  before_filter :admin_user,   :only => [:index, :update_permissions]
  before_filter :set_locale
  before_filter :enterprise_activated?

  def index
    @users = User.where(:deleted_user => false).asc(:fullname).page(params[:page])
  end

  def new
    if signed_in?
      redirect_to user_projects_path and return
    end

    promo_code = params[:promo_code]
    @user = User.new
    return if promo_code.to_s.empty?

    @user.promo_code = promo_code
    cookies.permanent.signed[:promo_code] = promo_code
  end

  def created
    render 'create'
  end

  def create
    @user = create_user_form params
    if Set['1', 'on', 'true'].include? params[:user][:terms]
      @user[:terms] = true
    else
      @user[:terms] = false
    end

    @user[:datenerhebung] = @user[:terms]

    unless UserService.valid_user?(@user, flash)
      flash[:error] = t(flash[:error])
      redirect_to signup_path and return
    end

    @user.create_username
    @user.create_verification

    refer_name = cookies.signed[:veye_refer]
    check_refer refer_name, @user

    promo_code = params[:user][:promo_code]
    check_promo_code promo_code, @user

    if @user.save
      Thread.new{ @user.send_verification_email }
    else
      flash[:error] = "#{t(:general_error)} - #{@user.errors.full_messages.to_sentence}"
      redirect_to signup_path
    end
  end

  def create_mobile
    @user = create_user_form params
    if Set['1', 'on', 'true'].include? params[:user][:terms]
      @user[:terms] = true
    else
      @user[:terms] = false
    end

    @user[:datenerhebung] = @user[:terms]

    if UserService.valid_user?(@user, flash)
      @user.create_username
      @user.create_verification
      if @user.save
        @user.send_verification_email
        sign_in @user
        redirect_to '/lottery/libraries'
      else
        flash[:error] = "#{t(:general_error)} - #{@user.errors.full_messages.to_sentence}"
        redirect_to :back and return
      end
    else
      flash[:error] = t(flash[:error])
      redirect_to :back
    end
  end


  def show
    @user = User.find_by_username(params[:id])
    if @user
      @userlinkcollection = Userlinkcollection.find_all_by_user( @user.id )
      @products = Array.new
      if has_permission_to_see_products( @user, current_user ) && !@user.nil?
        @products = @user.products.paginate(:page => params[:page], :per_page => 3)
      end
      @comments = Array.new
      if has_permission_to_see_comments( @user, current_user ) && !@user.nil?
        @comments = Versioncomment.find_by_user_id( @user.id ).paginate(:page => params[:page], :per_page => 3)
        @comments_count = Versioncomment.count_by_user_id( @user.id )
        @comments_count = 0 if @comments_count.nil?
      end
    else
      flash.now[:error] = "There is no user with the given username"
    end
  end

  def favoritepackages
    @user = User.find_by_username(params[:id])
    return if @user.nil?
    @products = Array.new
    respond_to do |format|
      format.html {
        @userlinkcollection = Userlinkcollection.find_all_by_user( @user.id )
        if has_permission_to_see_products( @user, current_user ) && !@user.nil?
          @products = @user.products.paginate(:page => params[:page])
        end
      }
      format.json {
        render :json => "Please use our API at https://www.versioneye.com/api"
      }
      format.rss {
        if has_permission_to_see_products( @user, current_user ) && !@user.nil?
          # load the 30 newest notifications
          @notifications = Notification.by_user_id( @user.id )
        end
        render  :layout => false
      }
    end
  end

  def comments
    @page = "profile"
    @user = User.find_by_username(params[:id])
    return nil if @user.nil?
    @userlinkcollection = Userlinkcollection.find_all_by_user( @user.id )
    @comments = Array.new
    if has_permission_to_see_comments( @user, current_user ) && !@user.nil?
      @comments = Versioncomment.find_by_user_id( @user.id ).paginate(:page => params[:page])
      @count = Versioncomment.count_by_user_id( @user.id )
    end
  end

  def activate
    verification = params[:verification]
    source       = params[:source]

    message   = "Congratulation. Your Account is activated."
    user      = User.where(verification: verification).shift
    activated = User.activate!( verification )

    if activated

      if github_source?( source ) || bitbucket_source?( source )
        sign_in user
        flash.now[:success] = message
        redirect_to user_packages_i_follow_path
        return
      end

      flash[:success] = message
      return
    end

    if UserEmail.activate!( verification )
      flash.now[:success] = "Congratulation. Your email address is now verified."
      return
    end

    flash.now[:error] = "The activation code could not be found. Maybe your Account is already activated."
  end

  def users_location
    user = User.find_by_username(params[:id])
    location = user ? user.location : 'Berlin'
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
      UserService.reset_password user
      flash[:success] = "Please check your E-Mails. You should receive an E-Mail with a new password."
    end
    redirect_to iforgotmypassword_path
  end

  def show_update_password
    @verification = params[:verification]
    user = User.by_verification(@verification).first
    if @verification.nil? or user.nil?
      render text: "Verification code is wrong, malformed or doesnt exist. If
      it's mistake, please send feedback to our customer support.",
             layout: "application"
      return false
    end
    render 'updatepassword'
  end

  def update_password
    has_failure = false
    password = params[:password]
    password2 = params[:password2]
    verification_code = params[:verification]

    user = User.by_verification(verification_code).first

    if user.nil?
      flash[:error] = "Wrong verification code. If it's mistake, please send feedback to our customer support."
      has_failure = true
    elsif password.empty? or password != password2
      flash[:error] = "Passwords don't match."
      has_failure = true
    end

    unless user.update_password( password )
      has_failure = true
      flash[:error] = "Can't save new password:\n #{user.errors.full_messages.to_sentence}"
    end
    if has_failure
      redirect_to :back
      return false
    end

    user.verification = nil
    user.save

    flash[:success] = "Your password is now successfully changed and you can signin by using your fresh password."
    redirect_to signin_path
  end

  def autocomplete
    term = params[:term]
    if term.nil?
      render json: [] and return
    end
    matched_users = UserService.search(term)
    render json: format_autocompletion( matched_users )
  end

  # Only for Admins!
  def update_permissions
    user = User.find_by_username(params[:id])
    if user.nil?
      flash[:error] = "User could't find in the database."
    else
      if params[:commit].eql?('delete')
        UserService.delete user
        flash[:success] = "User deleted"
      else
        user.admin = params[:admin]
        user.fetch_or_create_permissions.lwl = params[:lwl]
        user.fetch_or_create_permissions.save
        user.save
        flash[:success] = "User updated"
      end
    end
    redirect_to users_path
  end

  private

    def create_user_form params
      user = User.new
      user.fullname   = params[:user][:fullname]
      user.email      = params[:user][:email]
      user.password   = params[:user][:password]
      user.promo_code = params[:user][:promo_code]
      user
    end

    def github_source?( source )
      !source.nil? && !source.empty? && source.eql?("github")
    end

    def bitbucket_source?( source )
      !source.nil? && !source.empty? && source.eql?("bitbucket")
    end

    def format_autocompletion(matched_users)
      results = []
      return results if matched_users.nil?

      matched_users.each_with_index do |user, i|
        next if user.username.eql?("admino") || user.fullname.eql?("Administrator")
        results << {
          value: user[:username],
          fullname: user[:fullname],
          username: user[:username]
        }
        break if i > 9
      end

      results
    end

    def correct_user
      @user = User.find_by_username(params[:id])
      redirect_to(root_path) unless current_user?(@user)
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end

    def check_refer(refer_name, user)
      if refer_name
        refer = Refer.get_by_name(refer_name)
        if refer
          user.refer_name = refer.name
        end
      end
    rescue => e
      logger.error "ERROR in check_refer: #{e.message}"
      logger.error e.stacktrace.join "\n"
      nil
    end

end
