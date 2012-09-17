class UserNotificationSetting
  
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :newsletter_news, type: Boolean, default: true      # getting general news from VersionEye
  field :newsletter_features, type: Boolean, default: true  # getting new features newsletter from VersionEye

  def self.get_by_user_id(id)
  	UserNotificationSetting.where(user_id: id)[0]
  end

  def self.send_newsletters_features
    users = User.all()
    users.each do |user|
      notification_settings = user.notification_settings
      if user.deleted != true && notification_settings.newsletter_features
        UserNotificationSetting.send_newsletter_new_features_for_user( user )
      end
    end
  end

  def self.send_newsletter_new_features_for_user( user )
    p "send newsletter about new features to user #{user.fullname} - start"
    NewsletterMailer.newsletter_new_features_email(user).deliver
  rescue => e
    p "An error occured. E-Mail inactive: #{user.fullname} - #{user.email}"
    p "ERROR #{e}"
    e.backtrace.each do |message| 
      p " - #{message}"
    end
  end

end