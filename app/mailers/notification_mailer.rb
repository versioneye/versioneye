class NotificationMailer < ActionMailer::Base

  layout 'email_html_layout'
  default from: "\"VersionEye\" <notify@versioneye.com>"

  def new_version_email(user, notifications)
    @user = user
    @notifications = notifications
    @link =  "#{Settings.server_url}/"
    @user_product_index = ProjectService.user_product_index_map( user )

    names = first_names notifications
    mail(
      :to => @user.email,
      :subject => "Update: #{names}",
      :tag => 'notification_new_version'
      )
  end

  def status(count)
    @count = count
    mail(
      :to => 'reiz@versioneye.com',
      :subject => "#{count} notifications",
      :tag => 'notification_status'
      )
  end

  private

    def first_names notifications
      names = Array.new
      max = 2
      max = 1 if notifications.size == 2
      max = 0 if notifications.size == 1
      (0..max).each do |num|
        notification = notifications[num]
        names.push notification.product.name
      end
      result = names.join(', ')
      if notifications.size > 3
        result = "#{result} ..."
      end
      result
    end

end
