class NotificationsController < ApplicationController

  before_action :authenticate

  def index
    page = params[:page]
    page = 1 if page.to_i < 1
    @notifications = Notification.by_user( current_user ).desc( :created_at ).paginate(:page => page.to_i)
    @notifications.each do |noti|
      noti.read = true
      noti.save
    end
  end

end
