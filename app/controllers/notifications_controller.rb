class NotificationsController < ApplicationController 

  def index 
    @notifications = Notification.by_user( current_user ).desc( :created_at ).limit(30)
  end 

end 
