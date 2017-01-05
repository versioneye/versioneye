class NotificationsController < ApplicationController

  before_filter :authenticate

  def index
    @notifications = Notification.by_user( current_user ).desc( :created_at ).limit(30)
    @notifications.each do |noti|
      noti.read = true
      noti.save
    end
  end

end
