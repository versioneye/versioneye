class Settings::EmailsController < ApplicationController

  before_filter :authenticate

  def index
    @user = current_user
  end

  def add_email
    email = params[:email]

    user = User.find_by_email(email)
    user_email = UserEmail.find_by_email(email)
    if user || user_email
      flash[:error] = 'The E-Mail Address exist already in our system. Please choose another one.'
      redirect_to settings_emails_path()
      return
    end

    user_email = UserEmail.new
    user_email.email = email
    user_email.user_id = current_user.id
    user_email.create_verification if !Settings.instance.environment.eql?('enterprise')
    if user_email.save
      send_verification_email current_user, user_email
      flash[:success] = 'E-Mail Address added.'
    else
      flash[:error] = 'E-Mail Address is not valid.'
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
      flash[:success] = 'Default E-Mail Address changed successfully.'
    else
      flash[:error] = 'An error occured. Please try again later.'
    end
    redirect_to settings_emails_path()
  end

  private

    def send_verification_email user, user_email
      return false if Settings.instance.environment.eql?('enterprise')
      UserMailer.verification_email_only(user, user_email.verification, user_email.email).deliver
    end

end
