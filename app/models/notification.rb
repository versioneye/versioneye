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
  
  scope :all_not_sent, where(sent_email: false)
  scope :by_user_id, ->(user_id){where(user_id: user_id).desc(:created_at).limit(30)}

  def user
    User.find_by_id( self.user_id )
  end

  def product 
    Product.find(self.product_id)
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
    user = User.find_by_email( "reiz@versioneye.com" )
    send_notifications_for_user( user )
  end
  
  def self.send_notifications
    count = 0
    user_ids = Notification.all.distinct(:user_id)
    user_ids.each do |id|
      user = User.find_by_id( id )
      if !user.nil? && user.deleted != true
          if send_notifications_for_user( user )
            count = count + 1
          end
      else
        p " -- no user found for id: #{id} "
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
    if !notifications.nil? && !notifications.empty?
      notifications.sort! { |a,b| a.product_id <=> b.product_id }
      NotificationMailer.new_version_email(user, notifications).deliver
      p "send notifications for user #{user.fullname} start"
      return true
    end
    return false
  end

end
