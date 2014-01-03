class Settings::PrivacyController < ApplicationController

  before_filter :authenticate

  def index
    @user = current_user
    @user.new_username = @user.username
  end

  def update
    privacy_products = validates_privacy_value params[:following_products]
    privacy_comments = validates_privacy_value params[:comments]
    password         = params[:password]
    user = current_user
    user.privacy_products = privacy_products
    user.privacy_comments = privacy_comments
    if password.nil? || password.empty?
      flash[:error] = 'Please type in the password!'
    elsif User.authenticate(current_user.email, password).nil?
      flash[:error] = 'The password is wrong. Please try again.'
    elsif user.save
      flash[:success] = 'Profile updated.'
    else
      flash[:error] = 'Something went wrong. Please try again later.'
    end
    redirect_to settings_privacy_path()
  end

  private

    def validates_privacy_value value
      return 'everybody' if value.nil? || value.empty?
      return value if value.eql?('everybody') || value.eql?('nobody') || value.eql?('ru')
      'everybody'
    end

end
