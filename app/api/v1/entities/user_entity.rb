require 'grape'

module VersionEye
  module Entities
    
    class UserEntity < Grape::Entity
      expose :fullname
      expose :username
    end

    class UserDetailedEntity < Entities::UserEntity
      expose :email
      expose :plan_name_id
      expose :admin
      expose :deleted
      expose :notifications
    end
    
  end
end
