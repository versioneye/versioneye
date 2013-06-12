class NotificationMigration

  def self.migrate_all
    Notification.all.each do |notification|
      if notification.user_id.is_a? String
        notification.user
        notification.save
        p "convert for #{notification.user.fullname}"
      end
    end
  end

end
