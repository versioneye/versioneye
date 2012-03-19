class Notification
  
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :product_id, type: String  
  field :version_id, type: String
  field :read, type: Boolean, default: false
  field :sent_email, type: Boolean, default: false
  
  validates_presence_of :user_id,    :message => "User is mandatory!"
  validates_presence_of :product_id, :message => "Product is mandatory!"
  
  def user
    if self.user_id.size < 3
      User.find( self.user_id.to_i )
    else
      User.find( self.user_id )
    end
  end
  
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
    notifications = Notification.all( conditions: {sent_email: "false"} )
    notifications.each do |notification|
      user = notification.user
      product = Product.find_by_id(notification.product_id)
      version = product.get_version(notification.version_id)
      NotificationMailer.new_version_email(user, version, product).deliver
      notification.sent_email = true
      notification.save
    end
    p "send notifications end"
  end
  
  def self.send_notifications_for_user(user)
    p "send notifications for user start"
    notifications = Notification.all( conditions: {sent_email: "false", user_id: user.id.to_s} )
    notifications.each do |notification|
      product = Product.find_by_id(notification.product_id)
      version = product.get_version(notification.version_id)
      NotificationMailer.new_version_email(user, version, product).deliver
      notification.sent_email = true
      notification.save
    end
    p "send notifications for user end"
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

end