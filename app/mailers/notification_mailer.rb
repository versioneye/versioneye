class NotificationMailer < ActionMailer::Base
  default from: "\"VersionEye\" <notify@versioneye.com>"
  
  def new_version_email(user, notifications)
    @user = user
    @notifications = notifications
    @link = "#{configatron.server_url}/package/"
    mail(
      :to => @user.email, 
      :subject => "Notification",
      :tag => "notification_new_version"
      )
  end

  def status(count)
    @count = count
    mail(
      :to => "reiz@versioneye.com",
      :subject => "#{count} notifications",
      :tag => "notification_status"
      )
  end
  
end