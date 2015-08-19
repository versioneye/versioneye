class NotificationsController < ApplicationController

  before_filter :authenticate

  def index
    @notifications = Notification.by_user( current_user ).desc( :created_at ).limit(30)
  end

end
