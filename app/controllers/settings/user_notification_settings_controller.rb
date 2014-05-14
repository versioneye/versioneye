class Settings::UserNotificationSettingsController < ApplicationController

  before_filter :authenticate

  def index
    @user_notification = UserNotificationSetting.fetch_or_create_notification_setting current_user
  end

  def update
    @user_notification                     = current_user.user_notification_setting
    @user_notification.newsletter_news     = params[:general_news]
    @user_notification.newsletter_features = params[:new_feature_news]
    @user_notification.notification_emails = params[:notification_emails]
    if @user_notification.save
      flash[:success] = 'Your changes have been saved successfully.'
    else
      flash[:error] = 'An error occured. Please try again later.'
    end
    redirect_to settings_notifications_path
  end

end
