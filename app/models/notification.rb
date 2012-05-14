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
    User.find_by_id( self.user_id )
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
  
  def self.send_to_rob
    user = User.find_by_id( 1 )
    send_notifications_for_user( user )
  end
  
  def self.send_notifications
    user_ids = Notification.all.distinct(:user_id)
    user_ids.each do |id|
      user = User.find_by_id( id )
      if !user.nil?
        send_notifications_for_user( user )
      else
        p " -- no user found for id: #{id} "
        notifications = Notification.all( conditions: {user_id: id} )
        notifications.each do |noti|
          p " ---- remove notification for user id: #{id} "
          noti.remove
        end        
      end
    end    
  end      
  
  def self.send_notifications_for_user(user)    
    notifications = Notification.all( conditions: {sent_email: "false", user_id: user.id.to_s} )
    if !notifications.nil? && !notifications.empty?
      p "send notifications for user #{user.fullname} start"
      NotificationMailer.new_version_email(user, notifications).deliver
      p "send notifications for user end"
    end
  end

  def self.send_newsletters
    users = User.all()
    users.each do |user|
      Notification.send_newsletter_for_user(user)
    end
  end

  def self.send_newsletter_for_user(user)
    p "send notifications for user #{user.fullname} start"
    NewsletterMailer.newsletter_email(user).deliver
    p "send notifications for user #{user.fullname} end"
  end

end