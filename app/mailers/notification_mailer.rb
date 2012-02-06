class NotificationMailer < ActionMailer::Base
  default from: "\"VersionEye\" <notify@versioneye.com>"
  
  def new_version_email(user, version, product)
    @user = user
    @version = version
    @product = product
    @link = "#{configatron.server_url}/product/#{@product.to_param}/version/#{@version.to_url_param}/#{@product.get_decimal_version_uid}"
    mail(
      :to => @user.email, 
      :subject => "Notification",
      :tag => "notification_new_version"
      )
  end
  
end