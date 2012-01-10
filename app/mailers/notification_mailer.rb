class NotificationMailer < ActionMailer::Base
  default from: "\"VersionEye\" <notify@versioneye.com>"
  
  def new_version_email(user, version, product)
    @user = user
    @version = version
    @product = product
    mail(
      :to => @user.email, 
      :subject => "Notification",
      :tag => "my-tag"
      )
  end
  
end