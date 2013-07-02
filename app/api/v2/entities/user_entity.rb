require 'grape'

module V2
  module Entities
    
    class UserEntity < Grape::Entity
      expose :fullname
      expose :username
    end

    class UserDetailedEntity < Entities::UserEntity
      expose :email
      expose :admin
      expose :deleted
      expose :notifications
    end
    
  end
end
