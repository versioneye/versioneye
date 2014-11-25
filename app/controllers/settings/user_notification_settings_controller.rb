class Settings::UserNotificationSettingsController < ApplicationController

  before_filter :authenticate

  def index
    @user_notification = UserNotificationSetting.fetch_or_create_notification_setting current_user
  end

  def update
    general_news  = params[:general_news]
    feature_news  = params[:new_feature_news]
    notifications = params[:notification_emails]
    projects      = params[:project_emails]

    general_news  = false if general_news.to_s.empty?
    feature_news  = false if feature_news.to_s.empty?
    notifications = false if notifications.to_s.empty?
    projects      = false if projects.to_s.empty?

    @user_notification                     = current_user.user_notification_setting
    @user_notification.newsletter_news     = general_news
    @user_notification.newsletter_features = feature_news
    @user_notification.notification_emails = notifications
    @user_notification.project_emails      = projects
    if @user_notification.save
      flash[:success] = 'Your changes have been saved successfully.'
    else
      flash[:error] = 'An error occured. Please try again later.'
    end
    redirect_to settings_notifications_path
  end

end
