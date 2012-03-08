class NotificationSql < ActiveRecord::Base

  set_table_name "notifications"

  belongs_to :user,           :class_name => "UserSql"

  validates :product_id, :presence => true
  validates :version_id, :presence => true
  
  def self.send_notifications_job
    one_min = 60
    one_hour = one_min * 60
    while true do
      send_notifications
      p "start to make a nap"
      sleep one_hour
      p "wake up and work a little bit"
    end
  end  
  
  def self.send_notifications
    p "send notifications start"
    Notification.find_each(:conditions => "sent_email is false") do |notification|
      user = notification.user
      product = Product.find_by_id(notification.product_id)
      version = product.get_version(notification.version_id)
      NotificationMailer.new_version_email(user, version, product).deliver
      notification.sent_email = true
      notification.save
    end
    p "send notifications end"
  end
  
  def self.send_test_notification
    user = User.new
    user.fullname = "Robert Reiz"
    user.email = "robert.reiz.81@gmail.com"
    version = Version.new
    version.version = "1.0"
    product = Product.new
    product.name = "VersionEyeProduct"
    product.prod_key = "org.spring/spring-core"
    NotificationMailer.new_version_email(user, version, product).deliver          
  end
  
  def self.migrate_to_mongo
    notifications = NotificationSql.all
    notifications.each do |notification|
      p "notification: #{notification.id}"
      noti = Notification.new
      noti.user_id = notification.user_id
      noti.product_id = notification.product_id
      noti.version_id = notification.version_id
      noti.read = notification.read
      noti.sent_email = notification.sent_email
      noti.save
    end
  end

end