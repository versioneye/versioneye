class Notification < ActiveRecord::Base

  belongs_to :user,           :class_name => "User"
  belongs_to :unsigneduser,   :class_name => "Unsigneduser"  

  validates :product_id, :presence => true
  validates :version_id, :presence => true
  
  def self.send_notifications_job
    one_min = 60
    one_hour = one_min * 60
    while true do
      send_notifications
      p "start to make a nap"
      sleep one_hour
      p "wake up"
    end
  end
  
  def self.send_notifications
    Notification.find_each(:conditions => "sent_email is false") do |notification|
      user = fetch_user notification
      version = notification.version
      product = version.product
      ProductMailer.new_version_email(user, version, product).deliver
      notification.sent_email = true
      notification.save
    end
  end
  
  private 
  
    def self.fetch_user notification
      user = notification.user
      if user.nil? 
        user = User.new
        unsigenduser = notification.unsigneduser
        user.email = unsigenduser.email
        user.fullname = user.email
      end
      user
    end

end