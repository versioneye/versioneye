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

  def self.disable_all_for_user(user_id)
    notifications = Notification.all( conditions: {user_id: user_id} )
    if !notifications.nil? && !notifications.empty?
      notifications.each do |notification|
        notification.sent_email = true;
        notification.save
      end
    end
  end
  
  def self.send_to_rob
    user = User.find_by_email( "robert.reiz.81@gmail.com" )
    send_notifications_for_user( user )
  end
  
  def self.send_notifications
    count = 0
    user_ids = Notification.all.distinct(:user_id)
    user_ids.each do |id|
      user = User.find_by_id( id )
      if !user.nil?
        send_notifications_for_user( user )
        count = count + 1
      else
        logger.error " -- no user found for id: #{id} "
        notifications = Notification.all( conditions: {user_id: id} )
        notifications.each do |noti|
          p " ---- remove notification for user id: #{id} "
          noti.remove
        end        
      end
    end
    NotificationMailer.status(count).deliver
  end      
  
  def self.send_notifications_for_user(user)    
    notifications = Notification.all( conditions: {sent_email: "false", user_id: user.id.to_s} )
    notifications.sort! { |a,b| a.product_id <=> b.product_id }
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
  rescue
    p "An error occured. E-Mail inactive: #{user.fullname} - #{user.email}"
  end

end