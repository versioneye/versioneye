require 'grape'

module VersionEye
  module Entities
    class UserEntity < Grape::Entity
      expose :fullname
      expose :usename
    end

    class UserDetailedEntity < Entities::UserEntity
      expose :email
      expose :plan_name_id
      expose :admin
      expose :deleted
    end
  end
end
