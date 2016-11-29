class Settings::PrivacyController < ApplicationController

  before_filter :authenticate

  def index
    @user = current_user
    @user.new_username = @user.username
  end

  def update
    privacy_products = validates_privacy_value params[:following_products]
    privacy_comments = validates_privacy_value params[:comments]
    include_autocomp = validate_autocomplete   params[:include_in_autocomplete]
    user = current_user
    user.privacy_products        = privacy_products
    user.privacy_comments        = privacy_comments
    user.include_in_autocomplete = include_autocomp
    if user.save
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

    def validate_autocomplete value
      return true if value.to_s.empty?
      return true if value.to_s.eql?('yes')
      return false
    end

end
