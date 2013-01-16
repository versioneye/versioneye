require 'grape'

module VersionEye
  module Entities
    class UserFollowEntity < Grape::Entity
      expose :username
      expose :prod_key
      expose :follows
    end
  end
end
