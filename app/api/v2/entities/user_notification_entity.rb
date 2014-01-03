require 'grape'

require_relative 'user_entity.rb'
require_relative 'notification_entity.rb'

module EntitiesV2
  class UserNotificationEntity < Grape::Entity
    expose :user_info, using: UserEntity, as: 'user'
    expose :unread
    expose :notifications, :using => NotificationEntity
  end
end