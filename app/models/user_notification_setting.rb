class UserNotificationSetting

  include Mongoid::Document
  include Mongoid::Timestamps

  # Receiving general news from VersionEye. For example about Investments.
  field :newsletter_news,     type: Boolean, default: true

  # Receiving the newsletter about new features
  field :newsletter_features, type: Boolean, default: true

  belongs_to :user

  def self.email_logger
    ActiveSupport::BufferedLogger.new('log/email.log')
  end

  def self.send_newsletter_features
    count = 0
    users = User.all()
    users.each do |user|
      next if user.deleted || user.email_inactive
      notification_setting = self.fetch_or_create_notification_setting( user )
      if notification_setting.newsletter_features
        UserNotificationSetting.send_newsletter_new_features_for_user( user )
        count += 1
      end
    end
    count
  end

  def self.fetch_or_create_notification_setting user
    if user.user_notification_setting.nil?
      user.user_notification_setting = UserNotificationSetting.new
      user.save
    end
    user.user_notification_setting
  end

  def self.send_newsletter_new_features_for_user( user )
    email_logger.info "Send new feature newsletter to #{user.fullname}"
    NewsletterMailer.newsletter_new_features_email(user).deliver
  rescue => e
    user.email_send_error = e.message
    user.save
    email_logger.error e.message
    email_logger.error e.backtrace.join("\n")
  end

end
